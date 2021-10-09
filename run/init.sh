if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -n "$JOSH_DEST" ]; then
        VERBOSE=1

    elif [ -z "$JOSH" ]; then
        source "`dirname $0`/boot.sh"
        VERBOSE=0
    fi
fi


if [ -n "$HTTP_GET" ]; then
    echo

elif [ -x "`which curl`" ]; then
    export HTTP_GET="`which curl` -fsSL"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET" 1>&2

elif [ -x "`which wget`" ]; then
    export HTTP_GET="`which wget` -qO -"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET" 1>&2

elif [ -x "`which fetch`" ]; then
    export HTTP_GET="`which fetch` -qo - "
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using fetch: $HTTP_GET" 1>&2

elif [ -x "`which http`" ]; then
    export HTTP_GET="`which http` -FISb"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using httpie `http --version`: $HTTP_GET" 1>&2

else
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 1
fi


if [ -n "$(uname | grep -i freebsd)" ]; then
    export JOSH_OS="BSD"
    shortcut 'ls' '/usr/local/bin/gnuls' 1
    shortcut 'grep' '/usr/local/bin/grep' 1


elif [ -n "$(uname | grep -i darwin)" ]; then
    export JOSH_OS="MAC"
    shortcut 'ls' '/usr/local/bin/gls' 1
    shortcut 'grep' '/usr/local/bin/ggrep' 1

    export PATH="$PATH:/Library/Apple/usr/bin"

else
    if [ -n "$(uname | grep -i linux)" ]; then
        export JOSH_OS="LINUX"
    else
        echo " - ERROR: unsupported OS!"
        export JOSH_OS="UNKNOWN"
    fi
fi

if [ "$JOSH_OS" = 'BSD' ] || [ "$JOSH_OS" = 'MAC' ]; then
    shortcut 'cut' '/usr/local/bin/gcut' 1
    shortcut 'head' '/usr/local/bin/ghead' 1
    shortcut 'readlink' '/usr/local/bin/greadlink' 1
    shortcut 'realpath' '/usr/local/bin/grealpath' 1
    shortcut 'sed' '/usr/local/bin/gsed' 1
    shortcut 'tail' '/usr/local/bin/gtail' 1
fi

export JOSH_INIT=1
