#!/bin/sh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$HTTP_GET" ]; then
        source "`dirname $0`/../run/boot.sh"
    fi

    JOSH_CACHE_DIR="$HOME/.cache/josh"
    if [ ! -d "$JOSH_CACHE_DIR" ]; then
        mkdir -p "$JOSH_CACHE_DIR"
        echo " * make Josh cache directory \`$JOSH_CACHE_DIR\`"
    fi

    PYTHON_BINARIES="$HOME/.python"
    [ ! -d "$PYTHON_BINARIES" ] && mkdir -p "$PYTHON_BINARIES"

    if [ ! -d "$PYTHON_BINARIES" ]; then
        mkdir -p "$PYTHON_BINARIES"
        echo " * make Python default directory \`$PYTHON_BINARIES\`"
    fi

    if [ -n "$JOSH_DEST" ]; then
        BASE="$JOSH_BASE"
    else
        BASE="$JOSH"
    fi
fi

MIN_PYTHON_VERSION=3.6  # minimal version for modern pip
# MAX_PYTHON_VERSION=3.9

PIP_REQ_PACKAGES=(
    pip        # python package manager, first
    httpie     # super http client, just try: http head anything.com
    pipdeptree # simple, but powerful tool to manage python requirements
    setuptools
    sshuttle   # swiss knife for ssh tunneling & management
    thefuck    # misspelling everyday helper
    virtualenv # virtual environments for python packaging
    wheel
)

PIP_OPT_PACKAGES=(
    mycli      # python-driver MySQL client
    pgcli      # python-driver PostgreSQL client
    clickhouse-cli
    paramiko   # for ssh tunnels with mycli & pgcli
    nodeenv    # virtual environments for node packaging
    tmuxp      # tmux session manager
)


PIP_DEFAULT_KEYS=(
    --compile
    --disable-pip-version-check
    --no-input
    --no-input
    --no-python-version-warning
    --no-warn-conflicts
    --no-warn-script-location
    --prefer-binary
)

function python_distutils() {
    local distutils="`echo 'import distutils; print(distutils)' | $1 2>/dev/null | grep '<module'`"
    ([ "$distutils" ] && echo 1) || echo 0
}

function python_get_full_version() {
    if [ ! -x "$1" ]; then
        echo " - $0 fatal: isn't valid executable \'`$1\'`" >&2
        return 1
    fi
    echo "`$1 --version 2>&1 | grep -Po '([\d\.]+)$'`"
}

function python_get_version() {
    if [ ! -x "$1" ]; then
        echo " - $0 fatal: isn't valid executable \'`$1\'`" >&2
        return 1
    fi

    local python="`fs_realpath $1 2>/dev/null`"
    if [ ! -x "$python" ]; then
        echo " - $0 fatal: isn't valid python \'`$python\'`" >&2
        return 2
    fi

    local version="`python_get_full_version $python`"
    if [[ "$version" -regex-match '^[0-9]+\.[0-9]+' ]]; then
        echo "$MATCH"
    else
        echo " - $0 fatal: python $python==$version missing minor version" >&2
        return 3
    fi
}

function python_directory() {
    local version="`python_get_version $1`"
    [ -z "$version" ] && return 1
    echo "$PYTHON_BINARIES/$version"
}

function python_executable() {
    source $BASE/run/units/compat.sh
    if [ $? -gt 0 ]; then
        echo " - $0 fatal: something wrong, source BASE:\`$BASE\`" >&2
        return 127
    fi

    if [ -n "$PYTHONHOME" ]; then
        local link="$PYTHONHOME/bin/python"
        if [ -x "$link" ] && [ -x "`fs_realpath "$link" 2>/dev/null`" ]; then
            echo "$link"
            return 0
        fi
        unset PYTHONHOME
    fi

    local link="$PYTHON_BINARIES/default/bin/python"
    if [ -L "$link" ] && [ -x "`fs_realpath "$link" 2>/dev/null`" ]; then
        local version="`python_get_full_version $link`"
        [ -z "$version" ] && continue

        version_not_compatible "$MIN_PYTHON_VERSION" "$version"
        if [ $? -gt 0 ] && [ "`python_distutils $link`" -gt 0 ]; then
            echo "$link"
            return 0
        fi
    fi

    for dir in $(sh -c "echo "$PATH" | sed 's#:#\n#g' | sort -su"); do
        if [ ! -d "$dir" ] || [[ "$dir" -regex-match "$HOME" ]]; then
            continue
        fi

        for exe in $(find "$dir" -type f -name 'python*' 2>/dev/null | sort -Vr); do
            [ ! -x "$exe" ] || [[ ! "$exe" -regex-match '[0-9]$' ]] && continue

            local version="`python_get_full_version $exe`"
            [ -z "$version" ] && continue

            [[ ! "$version" -regex-match '^[0-9]+\.[0-9]+' ]] && continue

            unset result
            version_not_compatible $MIN_PYTHON_VERSION $version
            [ $? -gt 0 ] && [ "`python_distutils $exe`" -gt 0 ] && local result="$exe"

            if [ "$result" ]; then
                echo " * $0 info: using python $version from $exe" >&2
                break
            fi
        done
        [ -n "$result" ] && break
    done

    if [ "$result" ]; then
        local python="`fs_realpath $result`"
        if [ -x "$python" ]; then
            fs_realpath "$python" 1>/dev/null
            [ "$?" -eq 0 ] && echo "$python"
        fi
    fi
    return 1
}

function python_init() {
    local python="`python_executable`"

    if [ -x "$python" ]; then
        local target="`python_directory $python`"

        if [ ! -x "$target/bin/python" ]; then
            mkdir -p "$target/bin"

            local version="`python_get_version $python`"
            if [ -z "$version" ]; then
                echo " - $0 fatal: version not found for $python" >&2
                return 1
            fi
            echo " * $0 info: link $python ($version) -> $target/bin/" >&2

            ln -s "$python" "$target/bin/python"
            if [ "$?" -gt 0 ]; then
                echo " - $0 fatal: something wrong on link :-\ " >&2
                return 2
            fi
            ln -s "$python" "$target/bin/python3"
            ln -s "$python" "$target/bin/"  # finally /pythonX.Y.Z

            mkdir -p "$target/lib/python$version" && \
            rsync --archive --links --times --exclude '__pycache__/' "/usr/local/lib/python$version/" "$target/lib/python$version/"
            if [ "$?" -gt 0 ]; then
                echo " - $0 fatal: something wrong on copy stdlib /usr/local/lib/python$version/ -> $target/lib/python$version/" >&2
                return 3
            fi
            ln -s "$target" "`fs_dirname $target`/default"
            echo " * $0 info: isolated environment $target/lib/python$version/ ok" >&2

        fi
    else
        return 1
    fi

    export PATH="$target/bin:$PATH"
    export PYTHONHOME="$target"
    echo "$target"
    return 0
}

function pip_init() {
    local target="`python_init`"
    if [ ! -d "$target" ]; then
        echo " - $0 fatal: target=\`$target\`" >&2
        return 2
    fi

    if [ ! -x "$target/bin/pip" ]; then
        url="https://bootstrap.pypa.io/get-pip.py"
        local pip_file="/tmp/get-pip.py"

        local python="`python_executable`"
        if [ ! -x "$python" ]; then
            echo " - $0 fatal: python=\`$python\`" >&2
            return 3
        fi
        $SHELL -c "$HTTP_GET $url > $pip_file" && \
            PIP_REQUIRE_VIRTUALENV=false $python $pip_file \
                --prefix="$target" \
                --disable-pip-version-check \
                --no-input \
                --no-python-version-warning \
                --no-warn-conflicts \
                --no-warn-script-location \
                pip

        local retval=$?
        [ -f "$pip_file" ] && unlink "$pip_file"

        if [ "$retval" -gt 0 ]; then
            echo " - $0 fatal: pip deploy failed!" >&2
            return 1
        fi

        if [ ! -x "$target/bin/pip" ]; then
            echo " - $0 fatal: pip isn't exists in $target/bin/" >&2
            return 127
        fi
    fi

    export PATH="$target/bin:$PATH"
    export PYTHONHOME="$target"
    echo "$target/bin/pip"
    return 0
}

function venv_deactivate() {
    if [ -z "$VIRTUAL_ENV" ] || [ ! -f "$VIRTUAL_ENV/bin/activate" ]; then
        unset venv
    else
        local venv="$VIRTUAL_ENV"
        source $venv/bin/activate && deactivate
        echo "$venv"
    fi
}

function python_check() {
    python_init
    if [ ! -x "$JOSH_PYTHON" ]; then
        echo " - fatal: python>=$MIN_PYTHON_VERSION required!"
        return 1
    fi

    pip_init
    if [ ! -x "$JOSH_PIP" ]; then
        echo " - fatal: pip executive $JOSH_PIP isn't found!"
        return 2
    fi
}

function pip_install() {
    if [ -z "$*" ]; then
        echo " - $0 fatal: nothing to do" >&2
        return 1
    fi


    local venv="`venv_deactivate`"

    local pip="`pip_init`"
    [ ! -x "$pip" ] && return 2

    local target="`python_init`"
    if [ ! -d "$target" ]; then
        echo " - $0 fatal: target=\`$target\`"
        return 3
    fi

    local cmd="PIP_REQUIRE_VIRTUALENV=false $pip install --prefix=\"$target\" $PIP_DEFAULT_KEYS --upgrade --upgrade-strategy=eager"

    for row in $*; do
        $SHELL -c "$cmd $row"
    done

    # $SHELL -c "$pip  $*"

    # local retval="$?"
    # if [ "$retval" -gt 0 ]; then
    #     $SHELL -c "$pip --upgrade $@"
    #     local retval="$?"
    # fi

    [ -n "$venv" ] && source $venv/bin/activate
    # return $retval
}

function pip_update() {
    local pip="`pip_init`"
    [ ! -x "$pip" ] && return 1

    local venv="`venv_deactivate`"
    local josh_regex="$(
        echo "$PIP_REQ_PACKAGES $PIP_OPT_PACKAGES" | \
        sed 's:^:^:' | sed 's: *$:$:' | sed 's: :$|^:g')"

    local result="$(
        pipdeptree --all --warn silence --reverse | \
        grep -Pv '\s+' | sd '^(.+)==(.+)$' '$1' | grep -Po "$josh_regex" | sed -z 's:\n\b: :g'
    )"
    pip_install "$result"
    local retval="$?"

    [ -n "$venv" ] && source $venv/bin/activate
    return $retval
}

function pip_extras() {
    pip_install "$PIP_REQ_PACKAGES"
    run_show "pip_install $PIP_OPT_PACKAGES"
}

function python_env() {
    pip_init
}
