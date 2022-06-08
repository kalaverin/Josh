if [ "$commands[pastel]" ]; then
    function info {
        local msg="${@:2}"
        pastel paint -n limegreen " -- $0 ($1):" >&2
        pastel paint -n gray " $msg" >&2
        printf "\n" >&2
    }
    function warn {
        local msg="${@:2}"
        pastel paint -n yellow " ++ $0 ($1):" >&2
        printf " %s\n" "$msg" >&2
    }
    function fail {
        local msg="${@:2}"
        pastel paint -n red --bold " ** $0 ($1):" >&2
        pastel paint -n white " $msg" >&2
        printf "\n" >&2
    }
    function term {
        local msg="${@:2}"
        pastel paint -n white --on red --bold " ## $0 ($1):" >&2
        pastel paint -n white --bold " $msg" >&2
        printf "\n" >&2
    }
else
    function info {
        local msg="${@:2}"
        printf "\033[0;32m -- $0 ($1):\033[0m $msg\n" >&2
    }
    function warn {
        local msg="${@:2}"
        printf "\033[0;33m ++ $0 ($1):\033[0m $msg\n" >&2
    }
    function fail {
        local msg="${@:2}"
        printf "\033[1;31m ** $0 ($1):\033[0m $msg\n" >&2
    }
    function term {
        local msg="${@:2}"
        printf "\033[42m\033[0;101m ## $0 ($1):\033[0m $msg\n" >&2
    }
fi


if [ -x "$commands[fetch]" ]; then
    export HTTP_GET="$commands[fetch] -qo - "
    [ "$VERBOSE" -eq 1 ] && \
    info $0 "using fetch: $HTTP_GET"

elif [ -x "$commands[wget]" ]; then
    export HTTP_GET="$commands[wget] -qO -"
    [ "$VERBOSE" -eq 1 ] && \
    info $0 "using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET"

elif [ -x "$commands[http]" ]; then
    export HTTP_GET="$commands[http] -FISb"
    [ "$VERBOSE" -eq 1 ] && \
    info $0 "using httpie `http --version`: $HTTP_GET"

elif [ -x "$commands[curl]" ]; then
    export HTTP_GET="$commands[curl] -fsSL"
    [ "$VERBOSE" -eq 1 ] && \
    info $0 "using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET"

else
    fail $0 "curl, wget, fetch or httpie doesn't exists"
    return 127
fi


if [ -x "$commands[lz4]" ]; then
    export JOSH_PAQ="$commands[lz4] -1 - -"
    export JOSH_QAP="$commands[lz4] -d - -"

elif [ -x "$commands[zstd]" ]; then
    export JOSH_PAQ="$commands[zstd] -0 -T0"
    export JOSH_QAP="$commands[zstd] -qd"

elif [ -x "$commands[xz]" ] && [ -x "$commands[xzcat]" ]; then
    export JOSH_PAQ="$commands[xz] -0 -T0"
    export JOSH_QAP="$commands[xzcat]"

elif [ -x "$commands[gzip]" ] && [ -x "$commands[zcat]" ]; then
    export JOSH_PAQ="$commands[gzip] -1"
    export JOSH_QAP="$commands[zcat]"

else
    unset JOSH_PAQ
    unset JOSH_QAP
fi


if [ -n "$(uname | grep -i freebsd)" ]; then
    export JOSH_OS="BSD"
    shortcut 'ls'    '/usr/local/bin/gnuls' >/dev/null
    shortcut 'grep'  '/usr/local/bin/grep'  >/dev/null

elif [ -n "$(uname | grep -i darwin)" ]; then
    export JOSH_OS="MAC"
    shortcut 'ls'    '/usr/local/bin/gls'   >/dev/null
    shortcut 'grep'  '/usr/local/bin/ggrep' >/dev/null

    dirs=(
        bin
        sbin
        usr/bin
        usr/sbin
        usr/local/bin
        usr/local/sbin
    )

    for dir in $dirs; do
        if [ -d "/Library/Apple/$dir" ]; then
            export PATH="$PATH:/Library/Apple/$dir"
        fi
    done

else
    if [ -n "$(uname | grep -i linux)" ]; then
        export JOSH_OS="LINUX"
    else
        fail $0 "unsupported OS '$(uname -srv)'"
        export JOSH_OS="UNKNOWN"
    fi

    dirs=(
        bin
        sbin
        usr/bin
        usr/sbin
        usr/local/bin
        usr/local/sbin
    )

    for dir in $dirs; do
        if [ -d "/snap/$dir" ]; then
            export PATH="$PATH:/snap/$dir"
        fi
    done
fi

if [ "$JOSH_OS" = 'BSD' ] || [ "$JOSH_OS" = 'MAC' ]; then
    shortcut 'cut'       '/usr/local/bin/gcut'      >/dev/null
    shortcut 'find'      '/usr/local/bin/gfind'     >/dev/null
    shortcut 'head'      '/usr/local/bin/ghead'     >/dev/null
    shortcut 'readlink'  '/usr/local/bin/greadlink' >/dev/null
    shortcut 'realpath'  '/usr/local/bin/grealpath' >/dev/null
    shortcut 'sed'       '/usr/local/bin/gsed'      >/dev/null
    shortcut 'tail'      '/usr/local/bin/gtail'     >/dev/null
    shortcut 'tar'       '/usr/local/bin/gtar'      >/dev/null
    shortcut 'xargs'     '/usr/local/bin/gxargs'    >/dev/null
    export JOSH_MD5_PIPE="$(which md5)"
else
    export JOSH_MD5_PIPE="$(which md5sum) | $(which cut) -c -32"
fi

source "$(fs_dirname $0)/hier.sh"
