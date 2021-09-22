#!/bin/sh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$HTTP_GET" ] || [ -z "$JOSH" ] || [ -z "$JOSH_BASE" ]; then
        source "`dirname $0`/../run/boot.sh"
    fi

    JOSH_CACHE_DIR="$HOME/.cache/josh"
    if [ ! -d "$JOSH_CACHE_DIR" ]; then
        mkdir -p "$JOSH_CACHE_DIR"
        echo " * make Josh cache directory \`$JOSH_CACHE_DIR\`"
    fi

    if [ -n "$JOSH_DEST" ]; then
        BASE="$JOSH_BASE"
    else
        BASE="$JOSH"
    fi
fi

MIN_PYTHON_VERSION=3.6  # minimal version for modern pip

PIP_REQ_PACKAGES=(
    pip        # python package manager, first
    httpie     # super http client, just try: http head anything.com
    pipdeptree # simple, but powerful tool to manage python requirements
    setuptools
    sshuttle   # swiss knife for ssh tunneling & management
    virtualenv # virtual environments for python packaging
    wheel
)

PIP_OPT_PACKAGES=(
    mycli      # python-driver MySQL client
    pgcli      # python-driver PostgreSQL client
    nodeenv    # virtual environments for node packaging
)

function python_distutils() {
    local distutils="`echo 'import distutils; print(distutils)' | $1 2>/dev/null | grep from`"
    ([ "$distutils" ] && echo 1) || echo 0
}

function python_get_version() {
    if [ ! -x "$1" ]; then
        echo " - warning: isn't exists executable $1" >&2
    fi
    echo "`$1 --version 2>&1 | $JOSH_GREP -Po '([\d\.]+)$'`"
}

function python_exe() {
    source $BASE/run/units/compat.sh
    if [ $? -gt 0 ]; then
        echo " - fatal python: something wrong, source BASE:\`$BASE\`"
        return 255
    fi

    if [ -x "$PYTHON3" ]; then
        local version="`python_get_version $PYTHON3`"
        [ ! "$version" ] && continue

        version_not_compatible $MIN_PYTHON_VERSION $version
        [ $? -gt 0 ] && [ "`python_distutils $exe`" -gt 0 ] && return 0
    fi

    for dir in $(sh -c "echo "$PATH" | sed 's#:#\n#g' | sort -su"); do
        for exe in $(find $dir -type f -name 'python*' 2>/dev/null | sort -Vr); do
            local version="`python_get_version $exe`"
            [ ! "$version" ] && continue

            unset result
            version_not_compatible $MIN_PYTHON_VERSION $version
            [ $? -gt 0 ] && [ "`python_distutils $exe`" -gt 0 ] && local result="$exe"

            if [ "$result" ]; then
                echo " * info: python $version from $exe with distutils detected"
                break
            fi
        done
        [ "$result" ] && break
    done

    if [ "$result" ]; then
        local python="`realpath $result`"
        if [ -x "$python" ]; then
            export PYTHON3="$python"
            local version="`python_get_version $python`"
            return 0
        fi
    fi
    unset PYTHON3
    return 1
}

function python_init() {
    local cache_file="$JOSH_CACHE_DIR/python-executive"

    local result="`cat $cache_file 2>/dev/null`"
    if [ ! "$result" ] || [ ! -f "$result" ] || [ ! -f "$cache_file" ] || [ "`find $cache_file -mmin +1440 2>/dev/null | grep $cache_file`" ]; then
        [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"

        python_exe
        [ $? -eq 0 ] && echo "$PYTHON3" > "$cache_file"
        local result="`cat $cache_file 2>/dev/null`"
    fi

    if [ -f "$result" ]; then
        unset PYTHON3
        export PYTHON3="$result"
    fi

    [ "$PYTHON3" ] && [ -f "$PYTHON3" ] && return 0
    return 1
}

function pip_dir() {
    local cache_file="$JOSH_CACHE_DIR/pip-directory"

    local result="`cat $cache_file 2>/dev/null`"
    if [ ! -d "$result" ] || [ "`find $cache_file -mmin +1440 2>/dev/null | grep $cache_file`" ]; then
        [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"

        local local_bin="`$PYTHON3 -c 'from site import USER_BASE as base; print(base)'`/bin"
        [ ! -d "$local_bin" ] && mkdir -p "$local_bin"

        local result="$local_bin"
        local result="`realpath $local_bin`"
        [ $? -eq 0 ] && echo "$result" > "$cache_file"
    fi

    if [ ! "$result" ]; then
        echo " - fatal: PIP_DIR empty!" >&2
        return 2
    else
        [ ! -d "$result" ] && mkdir -p "$result"
        echo "$result"
    fi
}

function pip_init() {
    python_init
    if [ ! -f "$PYTHON3" ]; then
        return 1
    fi

    PIP_DIR="`pip_dir`"
    if [ ! -d "$PIP_DIR" ]; then
        echo " - fatal: PIP_DIR=\`$PIP_DIR\`"
        return 1
    fi

    export JOSH_PIP="$PIP_DIR/pip"
    export PATH="$PIP_DIR:$PATH"

    if [ ! -f "$JOSH_PIP" ]; then
        [ ! -d "$PIP_DIR" ] && mkdir -p "$PIP_DIR"
        url="https://bootstrap.pypa.io/get-pip.py"
        local pip_file="/tmp/get-pip.py"

        $SHELL -c "$HTTP_GET $url > $pip_file" && \
            PIP_REQUIRE_VIRTUALENV=false $PYTHON3 $pip_file \
                --disable-pip-version-check \
                --no-input \
                --no-python-version-warning \
                --no-warn-conflicts \
                --no-warn-script-location \
                --user \
                pip

        local retval=$?
        [ -f "$pip_file" ] && unlink "$pip_file"

        if [ "$retval" -gt 0 ]; then
            echo " - fatal: pip deploy failed!"
            return 1
        fi

        if [ ! -f "$JOSH_PIP" ]; then
            echo " - fatal: pip isn't installed ($JOSH_PIP)"
            return 255
        fi
    fi
    return 0
}

function pip_deploy() {
    python_init
    if [ ! -x "$PYTHON3" ]; then
        echo " - fatal: python>=$MIN_PYTHON_VERSION required!"
        return 1
    fi

    pip_init
    if [ ! -x "$JOSH_PIP" ]; then
        echo " - fatal: pip executive $JOSH_PIP isn't found!"
        return 2
    fi

    if [ ! "$VIRTUAL_ENV" ] || [ ! -f "$VIRTUAL_ENV/bin/activate" ]; then
        function reactivate() {}
    else
        local venv="$VIRTUAL_ENV"
        source $venv/bin/activate && deactivate
        function reactivate() {
            source $venv/bin/activate
        }
    fi

    local retval=0
    for line in $@; do
        $SHELL -c "PIP_REQUIRE_VIRTUALENV=false $JOSH_PIP install --disable-pip-version-check --no-input --no-python-version-warning --no-warn-conflicts --no-warn-script-location --user --upgrade --upgrade-strategy=eager $line"
        [ "$?" -gt 0 ] && local retval=1
    done

    reactivate; return $retval
}

function pip_extras() {
    pip_deploy "$PIP_REQ_PACKAGES $PIP_OPT_PACKAGES"
    return 0
}

function python_env() {
    pip_init
}
