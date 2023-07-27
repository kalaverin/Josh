#!/bin/sh

[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then

    PYTHON_BINARIES="$HOME/.py"
    if [ ! -d "$PYTHON_BINARIES" ]; then
        if [ -d "$HOME/.python" ] && [ -d "$HOME/.python/default/bin" ]; then
            mv "$HOME/.python" "$HOME/.py" && ln -s "$HOME/.py" "$HOME/.python"
        else
            mkdir -p "$PYTHON_BINARIES"
        fi
    fi

    SOURCES_CACHE+=("$THIS_SOURCE")

    MIN_PYTHON_VERSION=3.6  # minimal version for modern pip

    PIP_REQ_PACKAGES=(
        pip        # python package manager, first
        pipdeptree # simple, but powerful tool to manage python requirements
        setuptools
        virtualenv # virtual environments for python packaging
        wheel
    )
    PIP_OPT_PACKAGES=(
        asciinema  # shell movies recorder and player
        clickhouse-cli
        crudini    # ini configs parser
        httpie     # super http client, just try: http head anything.com
        mycli      # python-driver MySQL client
        nodeenv    # virtual environments for node packaging
        paramiko   # for ssh tunnels with mycli & pgcli
        pgcli      # python-driver PostgreSQL client
        pre-commit # pre-commit framework tool
        pycln      # python code cleaner
        ruff       # blazing fast linter
        sshtunnel  # too
        sshuttle   # swiss knife for ssh tunneling & management
        termtosvg  # write shell movie to animated SVG
        thefuck    # misspelling everyday helper
        tmuxp      # tmux session manager
        vulture    # dead code search
        yapf       # another one cleaner
    )
    PIP_DEFAULT_KEYS=(
        --compile
        --disable-pip-version-check
        --no-input
        --no-python-version-warning
        --no-warn-conflicts
        --no-warn-script-location
        --prefer-binary
    )
    function py.lib.exists {
        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
            return 2
        fi

        if [ -x "$2" ]; then
            local bin="$(fs.realpath "$2")"
            if [ ! -x "$bin" ]; then
                fail $0 "cannot get real path for '$2'"
                return 3
            fi
        else
            local bin="$(py.exe)"
        fi

        if [ -z "$(echo "import $1 as x; print(x)" | $bin 2>/dev/null | grep '<module')" ]; then
            fail $0 "'$1' module doesn't exist for '$bin'"
            return 1
        fi
    }

    function py.ver.full.raw {
        local version

        if [ -z "$1" ]; then
            if [ -n "$PYTHON" ] && [ -x "$PYTHON/bin/python" ]; then
                local source="$PYTHON/bin/python"

            else
                fail $0 "call without args, I need to do — what?"
                return 1
            fi
        else
            local source="$1"
        fi

        if [ ! -x "$source" ]; then
            fail $0 "isn't valid executable '$source'"
            return 1
        fi

        version="$($source --version 2>&1 | grep -Po "(\d+\.\d+\.\d+.*)")" || return "$?"
        printf "$version"
    }

    function py.ver.full {
        local version subversion
        local pattern='(\d+\.\d+\.\d+)'

        if [ -z "$1" ]; then
            if [ -n "$PYTHON" ] && [ -x "$PYTHON/bin/python" ]; then
                local source="$PYTHON/bin/python"

            else
                fail $0 "call without args, I need to do — what?"
                return 1
            fi
        else
            local source="$1"
        fi

        if [ ! -x "$source" ]; then
            fail $0 "isn't valid executable '$source'"
            return 1
        fi

        version="$(py.ver.full.raw "$source")" || return "$?"
        subversion="$($source --version 2>&1 | grep -Po "$pattern")" || return "$?"

        if [ ! "$PYTHON_ALLOW_ALPHABET" -gt 0 ]; then
            local pattern="$pattern$"
        fi

        version="$(printf "$version" 2>&1 | grep -Po "$pattern")"
        if [ -z "$version" ] && [ -n "$subversion" ]; then
            warn $0 "$source version $subversion doesn't match $($source --version); if you sure, set PYTHON_ALLOW_ALPHABET=1"
            return 1
        fi

        printf "$version"
    }

    function py.ver.uncached {
        py.ver.full "$python" >&2
        local python="$(fs.realpath "$1" 2>/dev/null)"
        if [ ! -x "$python" ]; then
            fail $0 "isn't valid python '$python'"
            return 3
        fi

        local version="$(py.ver.full "$python")"
        if [[ "$version" -regex-match '^[0-9]+\.[0-9]+' ]]; then
            printf "$MATCH"
        else
            fail $0 "python '$python'=='$version' empty minor version"
            return 1
        fi
    }

    function py.ver {
        if [ -z "$1" ]; then
            if [ -n "$PYTHON" ] && [ ! -x "$PYTHON/bin/python" ]; then
                if [ -x "$PYTHON_BINARIES/default/bin/python" ]; then
                    local source="$PYTHON_BINARIES/default/bin/python"
                else
                    fail $0 "call without args, default python doesn't exists: '$PYTHON_BINARIES/default/bin/python'"
                    return 1
                fi

            elif [ -n "$PYTHON" ] && [ -x "$PYTHON/bin/python" ]; then
                local source="$PYTHON/bin/python"

            else
                fail $0 "call without args, I need to do — what?"
                return 2
            fi
        else
            local source="$1"
        fi

        if [ ! -x "$source" ]; then
            fail $0 "isn't valid executable '$source'"
            return 3
        fi
        eval.cached "$(fs.mtime $source)" py.ver.uncached "$source"
    }

    function py.home.from_path {
        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
            return 1
        fi

        local version="$(py.ver "$1")"
        [ -z "$version" ] && return 1
        printf "$PYTHON_BINARIES/$version"
    }

    function py.exe.lookup {
        if [ -z "$ASH" ]; then
            fail $0 "\$ASH:'$ASH' isn't accessible"
            return 1
        fi

        source "$ASH/run/units/compat.sh"

        if [ -n "$*" ]; then
            local dirs="$*"
        else
            local dirs="$path"
        fi

        for dir in $(echo "$dirs" | sed 's#:#\n#g'); do
            if [ ! -d "$dir" ]; then
                continue
            fi

            for python in $(find "$dir" -maxdepth 1 -type f -name 'python?.*' 2>/dev/null | sort -Vr); do
                [ ! -x "$python" ] || \
                [[ ! "$python" -regex-match '[0-9]$' ]] && continue

                local version="$(py.ver.full $python)"
                [ "$?" -gt 0 ] || [ -z "$version" ] || \
                [[ ! "$version" -regex-match '^[0-9]+\.[0-9]+' ]] && continue

                unset result

                if ! version_not_compatible $MIN_PYTHON_VERSION $version; then
                    if py.lib.exists 'distutils' "$python"; then
                        local result="$python"
                    else
                        info $0 "python $python ($version) haven't distutils, skip"
                        continue
                    fi
                else
                    info $0 "python $python $version < $MIN_PYTHON_VERSION, skip"
                    continue
                fi
                [ "$result" ] && break
            done
        done
        if [ -n "$result" ]; then
            info $0 "python binary $result ($version)"
            printf "$result"
            return 0
        fi
        fail $0 "python binary not found"
        return 1
    }

    function py.exe {
        local version
        local link="$PYTHON_BINARIES/default/bin/python"

        if [ -n "$1" ]; then
            local result
            if [ -x "$1" ]; then
                result="$(fs.realpath "$1")" || return "$?"
                printf "$result"
                return 0
            fi
            fail $0 "\$1='$1' isn't accessible or exists"
            return 1
        fi

        if [ -n "$PYTHON" ]; then
            local real_path="$PYTHON/bin/python"
            if [ -x "$link" ] && [ -x "$real_path" ] && [ -e "$real_path" ] && [ "$(fs.realpath "$link")" = "$(fs.realpath "$real_path")" ]; then
                printf "$real_path"
                return 0
            fi
        fi

        if ! is.function "compat.executables"; then
            if [ ! -x "$ASH" ]; then
                fail $0 "\$ASH:'$ASH' isn't accessible"
                return 1
            fi
            source "$ASH/run/units/compat.sh"
        fi

        if [ -L "$link" ] && [ -x "$link" ] && [ -e "$link" ]; then
            version="$(py.ver.full "$link")"
            if [ "$?" -eq 0 ] && [ -n "$version" ]; then

                version_not_compatible "$MIN_PYTHON_VERSION" "$version"

                if [ "$?" -gt 0 ]; then
                    if py.lib.exists 'distutils' "$link"; then
                        printf "$link"
                        return 0
                    fi
                fi
            fi
        fi

        local gsed="$commands[gsed]"
        if [ ! -x "$gsed" ]; then
            local gsed="$(which sed)"
            if [ ! -x "$gsed" ]; then
                fail $0 "GNU sed for '$ASH_OS' don't found"
                return 2
            fi
        fi

        local dirs="$($SHELL -c "echo "$PATH" | sed 's#:#\n#g' | grep -v "$HOME" | sort -su | $gsed -z 's#\n#:#g' | awk '{\$1=\$1};1'")"
        if [ -z "$dirs" ]; then
            local dirs="$PATH"
        fi

        local result="$(
            eval.cached "`fs.lm.many $dirs $PYTHON_BINARIES`" py.exe.lookup $dirs)"

        if [ "$result" ]; then
            local python
            python="$(fs.realpath "$result")"
            if [ "$?" -eq 0 ] && [ -x "$python" ]; then
                printf "$python"
                return 0
            fi
        fi
        fail $0 "python doesn't exists in: '$dirs'"
        return 3
    }

    function py.home.uncached {
        local target
        local python="$1"

        if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
            fail $0 "py.executable and home directory can't detected"
            return 1
        fi

        target="$(py.home.from_path "$python")"
        if [ "$?" -eq 0 ] && [ ! -x "$target/bin/python" ]; then
            mkdir -p "$target/bin"
            info $0 "link $python ($(py.ver.full "$python")) -> $target/bin/"
        fi

        local version="$(py.ver "$python")"
        if [ -z "$version" ]; then
            fail $0 "version not found for $python"
            return 1
        fi

        if [ ! -x "$target/local" ]; then
            unlink "$target/local" 2>/dev/null
            ln -s "$target" "$target/local"
        fi

        if [ ! -x "$target/bin/python" ]; then
            unlink "$target/bin/python" 2>/dev/null
            ln -s "$python" "$target/bin/python"
        fi

        if [ ! -x "$target/bin/python${version[1]}" ]; then
            unlink "$target/bin/python${version[1]}" 2>/dev/null
            ln -s "$python" "$target/bin/python${version[1]}"
        fi

        ln -s "$python" "$target/bin/" 2>/dev/null # finally /pythonX.Y.Z

        if [ ! -x "$PYTHON_BINARIES/default" ]; then
            unlink "$PYTHON_BINARIES/default" 2>/dev/null
            ln -s "$target" "$PYTHON_BINARIES/default"
            info $0 "make default $python ($(py.ver.full "$python"))"
        fi
        path.rehash

        printf "$target"
    }

    function py.home {
        local python target
        if [ -z "$1" ]; then
            python="$(py.exe)"
        else
            python="$(which "$1")"
            if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
                fail $0 "python binary '$python' doesn't exists or something wrong"
                return 1
            fi
        fi

        target="$(eval.cached "$(fs.mtime $python)" py.home.uncached "$python")"
        local retval="$?"

        if [ "$retval" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python '$python' home directory isn't exist, try again"

            target="$(DO_NOT_READ=1 eval.cached "$(fs.mtime $python)" py.home.uncached "$python")"
            local retval="$?"

            if [ "$retval" -gt 0 ] || [ ! -d "$target" ]; then
                term $0 "python '$python' home directory isn't exist"
                return 2
            else
                warn $0 "python '$python' recovered with '$target'"
            fi
        fi

        printf "$target"

        if [ -z "$1" ]; then
            if [ ! -x "$PYTHON_BINARIES/default" ]; then
                ln -s "$target" "$PYTHON_BINARIES/default"
            fi
            export PYTHON="$target"
        fi
        [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
        return "$retval"
    }

    function py.set {
        local python source target version
        if [ -z "$1" ]; then

            if [ ! -x "$PYTHON_BINARIES/default/bin/python" ]; then
                fail "$0" "default python isn't installed, you call me without respect and arguments, I need to do — what?"
                return 1
            else

                source="$(fs.realpath "$PYTHON_BINARIES/default/bin/python")"
                if [ "$?" -gt 0 ] || [ ! -x "$source" ]; then
                    fail $0 "python default binary '$source' ($1) doesn't exists or something wrong"
                    return 2
                fi
            fi

        elif [[ "$1" -regex-match '^[0-9]+\.[0-9]+' ]]; then
            source="$(fs.realpath `which "python$MATCH"`)"
            if [ "$?" -gt 0 ] || [ ! -x "$source" ]; then
                fail $0 "python binary '$source' ($1) doesn't exists or something wrong"
                return 3
            fi

        else
            source="$(fs.realpath `which "$1"`)"
            if [ "$?" -gt 0 ] || [ ! -x "$source" ]; then
                fail $0 "python binary '$source' doesn't exists or something wrong"
                return 4
            fi
        fi

        if [ -w "$(fs.dirname "$source")" ]; then
            fail $0 "python path '$(fs.dirname "$source")' is writable"
            return 5
        fi

        version="$(py.ver.full "$source")"
        if [ "$?" -gt 0 ] || [ -z "$version" ]; then
            fail $0 "python $source version fetch"
            return 6

        elif [ -n "$PYTHON" ] && [ "$version" = "$(py.ver.full 2>/dev/null)" ]; then
            [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
            return 0
        fi

        target="$(py.home "$source")"
        if [ "$?" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python $source home directory isn't exist"
            return 7
        fi

        local base="$PYTHON"
        export PYTHON="$target"

        python="$(py.exe "$target/bin/python")"
        if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
            fail $0 "something wrong on setup python '$python' from source $source"
            [ -n "$base" ] && export PYTHON="$base"
            [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
            return 8
        fi

        if [ ! "$version" = "$(py.ver.full "$python")" ]; then
            fail $0 "source python $source ($version) != target $python ($(py.ver.full "$python"))"
            [ -n "$base" ] && export PYTHON="$base"
            [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
            return 9
        fi

        pip.deploy

        if [ -n "$1" ] && [ ! "$(py.ver "$PYTHON_BINARIES/default/bin/python" 2>/dev/null)" = "$(py.ver "$python" 2>/dev/null)" ]; then
            warn $0 "using python linked to $target (realpath $source v$version)"
        fi

        [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
        unset PIP
        path.rehash
        pip.lookup >/dev/null
        return 0
    }

    function pip.lookup {
        if [ -x "$PIP" ]; then
            printf "$PIP"
            return 0
        fi
        local target="$(py.home)"
        if [ "$?" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python target dir:'$target'"
            return 1
        fi

        local pip="$target/bin/pip"
        if [ -x "$pip" ]; then
            export PIP="$pip"
            printf "$pip"
            return 0
        fi

        warn $0 "pip binary not found"
        return 2
    }

    function pip.deploy {
        if [ -z "$1" ]; then
            local python="$(py.exe)"

        else
            local python="$(which "$1")"
            if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
                fail $0 "python binary '$python' doesn't exists or something wrong"
                return 1
            fi
        fi

        local target="$(py.home "$python")"
        if [ "$?" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python $py.home directory isn't exist"
            return 2
        fi

        if [ -z "$HTTP_GET" ]; then
            fail $0 "HTTP_GET isn't set"
            return 1

        elif [ ! -x "$(pip.lookup)" ]; then
            local version="$(py.ver "$python")"
            if [ -z "$version" ]; then
                fail $0 "python $py.ver fetch"
                return 3
            fi

            if [ "$version" = '2.7' ]; then
                local url='https://bootstrap.pypa.io/pip/2.7/get-pip.py'
            elif [ "$version" = '3.6' ]; then
                local url='https://bootstrap.pypa.io/pip/3.6/get-pip.py'
            else
                local url='https://bootstrap.pypa.io/get-pip.py'
            fi

            local pip_file="/tmp/get-pip.py"

            export PYTHON="$target"
            [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"

            info $0 "deploy pip with $python ($(py.ver.full $python)) to $target"

            local flags="--disable-pip-version-check --no-input --no-python-version-warning --no-warn-conflicts --no-warn-script-location"

            if [ "$(ash.branch 2>/dev/null)" = "develop" ]; then
                local flags="$flags -v"
            fi

            if [ "$USER" = 'root' ] || [ "$ASH_OS" = 'BSD' ] || [ "$ASH_OS" = 'MAC' ]; then
                local flags="--root='/' --prefix='$target' $flags"
            fi
            local command="PYTHONUSERBASE=\"$target\" PIP_REQUIRE_VIRTUALENV=false $python $pip_file $flags pip"

            warn $0 "$command"

            $SHELL -c "$HTTP_GET $url > $pip_file" && eval ${command} >&2

            local retval=$?
            [ -f "$pip_file" ] && unlink "$pip_file"

            if [ "$retval" -gt 0 ]; then
                fail $0 "pip deploy"
                return 4
            fi

            if [ ! -x "$(pip.lookup)" ]; then
                fail $0 "pip doesn't exists in '$target'"
                return 5
            fi

            local packages="$(find $target/lib/ -maxdepth 1 -type d -name 'python*')"
            if [ -d "$packages/dist-packages" ] && [ ! -d "$packages/site-packages" ]; then
                ln -s "$packages/dist-packages" "$packages/site-packages"
            fi

            path.rehash
            pip.install "$PIP_REQ_PACKAGES" >&2

        fi

        [ -z "$PYTHON" ] && export PYTHON="$target"
        [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"
    }

    function pip.exe.uncached {
        local python target

        python="$(py.exe)" || return "$?"

        target="$(py.home "$python")"
        local retval="$?"
        if [ "$retval" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python '$python' home directory doesn't exist"
            return 2
        fi

        pip.deploy >&2
        local retval="$?"

        if [ -x "$target/bin/pip" ]; then
            printf "$target/bin/pip"
        fi
        return "$retval"
    }

    function pip.exe {
        local result retval
        local gsed="$commands[gsed]"
        if [ ! -x "$gsed" ]; then
            local gsed="$(which sed)"
            if [ ! -x "$gsed" ]; then
                fail $0 "GNU sed for '$ASH_OS' don't found, return 1"
                return 1
            fi
        fi

        local dirs="$(print -r -- ${(q)PATH} | sed 's#:#\n#g' | grep -v "$HOME" | sort -su | $gsed -z 's#\n#:#g' | awk '{$1=$1};1')"
        if [ -z "$dirs" ]; then
            local dirs="$PATH"
        fi

        result="$(eval.cached "`fs.lm.many $dirs $PYTHON_BINARIES`" pip.exe.uncached $*)"
        retval="$?"

        if [ "$retval" -gt 0 ]; then
            fail $0 "evan.cached(pip.exe.uncached) failed, state=$retval, return 2"
            return 2
        fi

        [ -z "$PYTHON" ] && export PYTHON="$result"
        [ -x "$PYTHON" ] && export PYTHONUSERBASE="$PYTHON"

        if [ -x "$result" ]; then
            printf "$result"
            return 0
        fi

        fail $0 "evan.cached(pip.exe.uncached) empty or '$result' isn't exists, state=0, return 3"
        return 3
    }

    function venv.off {
        local name="$VIRTUAL_ENV"
        if [ -z "$name" ] || [ ! -f "$name/bin/activate" ]; then
            unset VIRTUAL_ENV
        else
            source "$name/bin/activate" && deactivate
            printf "$name"
        fi
        path.rehash
    }

    function pip.install {
        local pip venv

        function rollback() {
            term "$2:$1" "something went wrong, state=$3"
            [ -n "$venv" ] && source $venv/bin/activate
            printf "$3" && return "$3"
        }

        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
            return 1
        fi
        venv="$(venv.off)" || return "$(rollback "venv.off" "$0" "$?")"

        pip="$(pip.exe)"
        if [ "$?" -gt 0 ] || [ ! -x "$pip" ]; then
            return "$(rollback "pip.exe" "$0" 2)"
        fi

        local target="$(py.home)"
        if [ "$?" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python target dir '$target'"
            return "$(rollback "py.home" "$0" 3)"
        fi

        local flags="--upgrade --upgrade-strategy=eager"

        if [ "$(ash.branch 2>/dev/null)" != "develop" ]; then
            local flags="$flags -v"
        fi

        if [ "$USER" = 'root' ] || [ "$ASH_OS" = 'BSD' ] || [ "$ASH_OS" = 'MAC' ]; then
            local flags="--root='/' --prefix='$target' $flags"
        fi
        local command="PYTHONUSERBASE=\"$target\" PIP_REQUIRE_VIRTUALENV=false $(py.exe) -m pip install $flags $PIP_DEFAULT_KEYS"

        warn $0 "$command $*"

        local complete=''
        local failed=''
        for row in $@; do
            $SHELL -c "$command $row" >&2
            if [ "$?" -eq 0 ]; then
                if [ -z "$complete" ]; then
                    local complete="$row"
                else
                    local complete="$complete $row"
                fi
            else
                warn $0 "$row fails"
                if [ -z "$failed" ]; then
                    local failed="$row"
                else
                    local failed="$failed $row"
                fi
            fi
            printf "\n" >&2
        done
        path.rehash

        local result=''
        if [ -n "$complete" ]; then
            local result="$complete - success!"
        fi

        if [ -n "$failed" ]; then
            if [ -z "$result" ]; then
                local result="failed: $failed"
            else
                local result="$result $failed - failed!"
            fi
        fi

        if [ -n "$result" ]; then
            info $0 "$result"
        fi


        if [ -n "$failed" ]; then
            if [ -n "$complete" ]; then
                return "$(rollback "partial" "$0" 4)"
            else
                return "$(rollback "nothing" "$0" 5)"
            fi
        fi
        [ -n "$venv" ] && source $venv/bin/activate
        return 0
    }

    function pip.update {
        local python="$(py.exe)"
        if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
            return 1

        elif ! py.lib.exists 'pipdeptree' "$python"; then
            info $0 "pipdeptree isn't installed for $(py.ver), proceed"
            pip.install pipdeptree

            if ! py.lib.exists 'pipdeptree' "$python"; then
                fail $0 "something went wrong"
                return 2
            fi
        fi

        local package="$1"
        if [ -z "$package" ]; then
            local package="$PIP_REQ_PACKAGES $PIP_OPT_PACKAGES"
        fi

        local venv="$(venv.off)"
        local regex="$(
            echo "$package" | \
            sed 's:^:^:' | sed 's: *$:$:' | sed 's: :$|^:g')"

        local installed="$(
            $python -m pipdeptree --all --warn silence --reverse | \
            grep -Pv '\s+' | sd '^(.+)==(.+)$' '$1' | grep -Po "$regex" | sed -z 's:\n\b: :g'
        )"

        if [ -n "$1" ] && [ -z "$installed" ]; then
            printf "$regex"
            fail $0 "package '$1' isn't installed"
            return 3
        fi

        pip.install "$installed"
        local retval="$?"

        [ -n "$venv" ] && source $venv/bin/activate
        return $retval
    }

    function pip.extras {
        pip.install "$PIP_REQ_PACKAGES"
        local retval="$?"
        run.show "pip.install $PIP_OPT_PACKAGES"
        path.rehash

        if [ "$?" -gt 0 ] || [ "$retval" -gt 0 ]; then
            return 1
        fi
    }

    function pip.compliance.check {
        local target="$(py.home)"
        if [ "$?" -gt 0 ] || [ ! -d "$target" ]; then
            fail $0 "python target dir '$target'"
            return 1
        fi

        local result=""
        local expire="$(fs.lm.many $PATH)"
        local system="/bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin"

        if [ -n "$SUDO_USER" ]; then
            local home="$(fs.home.eval "$SUDO_USER")"

            if [ "$?" -eq 0 ] && [ -n "$home" ]; then
                local system="$system $home"
                local real="$(fs.realpath "$home")"
                if [ "$?" -eq 0 ] && [ ! "$home" = "$real" ]; then
                    local system="$system $real"
                fi
            fi
        fi

        for bin in $(find "$target/bin" -maxdepth 1 -type f 2>/dev/null | sort -Vr); do
            local short="$(basename "$bin")"

            local src="$target/bin/$short"
            local src_size="$(fs.size "$src")"
            local src_real="$(fs.realpath "$src")"

            if [ -n "$short" ] && [ -x "$src" ]; then
                local shadows="$(lookup.copies.cached "$short" "$expire" "$target/bin" $system "$VIRTUAL_ENV")"
                if [ -n "$shadows" ]; then
                    for dst in $(echo "$shadows" | sed 's#:#\n#g'); do
                        local dst_size="$(fs.size "$dst")"

                        if [ "$src_real" = "$(fs.realpath "$dst")" ]; then
                            continue
                        fi

                        local msg="$src ($src_size bytes) -> $dst ($dst_size bytes)"
                        if [ -n "$ASH_MD5_PIPE" ] && [ "$src_size" = "$dst_size" ]; then
                            local src_md5="$(cat "$src" | sh -c "$ASH_MD5_PIPE")"
                            local dst_md5="$(cat "$dst" | sh -c "$ASH_MD5_PIPE")"
                            if [ "$src_md5" = "$dst_md5" ]; then
                                local msg="$src ($src_size bytes) -> $dst (absolutely same, unlink last)"
                            fi
                        fi

                        if [ -z "$result" ]; then
                            local result="$msg"
                        else
                            local result="$result\n$msg"
                        fi
                    done
                fi
            fi
        done
        if [ -n "$result" ]; then
            warn $0 "one or many binaries may be shadowed"
            printf "$result\n" >&2
            warn $0 "disable execution by chmod a-x /file/path or unlink shadow from right side and run this test again by: $0"
        fi
    }
fi
