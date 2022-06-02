[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -n "$JOSH_DEST" ]; then
        VERBOSE=1

    elif [ -z "$JOSH" ]; then
        source "$(dirname $0)/boot.sh"
        VERBOSE=0
    fi
fi

if [ -x "$commands[fetch]" ]; then
    export HTTP_GET="$commands[fetch] -qo - "
    [ "$VERBOSE" -eq 1 ] && \
    printf " -- info ($0): using fetch: $HTTP_GET\n" >&2

elif [ -x "$commands[wget]" ]; then
    export HTTP_GET="$commands[wget] -qO -"
    [ "$VERBOSE" -eq 1 ] && \
    printf " -- info ($0): using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET\n" >&2

elif [ -x "$commands[http]" ]; then
    export HTTP_GET="$commands[http] -FISb"
    [ "$VERBOSE" -eq 1 ] && \
    printf " -- info ($0): using httpie `http --version`: $HTTP_GET\n" >&2

elif [ -x "$commands[curl]" ]; then
    export HTTP_GET="$commands[curl] -fsSL"
    [ "$VERBOSE" -eq 1 ] && \
    printf " -- info ($0): using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET\n" >&2

else
    printf " ** fail ($0): fatal: curl, wget, fetch or httpie doesn't exists\n" >&2
    return 127
fi


if [ -x "$commands[zstd]" ]; then
    export JOSH_PAQ="$commands[zstd] -0 -T0"
    export JOSH_QAP="$commands[zstd] -qd"

elif [ -x "$commands[lz4]" ]; then
    export JOSH_PAQ="$commands[lz4] -1 - -"
    export JOSH_QAP="$commands[lz4] -d - -"

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
        printf " ** fail ($0): unsupported OS '$(uname -srv)'\n" >&2
        export JOSH_OS="UNKNOWN"
    fi
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
