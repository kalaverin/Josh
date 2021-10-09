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
    shortcut 'ls' '/usr/local/bin/gnuls'
    shortcut 'grep' '/usr/local/bin/grep'


elif [ -n "$(uname | grep -i darwin)" ]; then
    export JOSH_OS="MAC"
    shortcut 'ls' '/usr/local/bin/gls'
    shortcut 'grep' '/usr/local/bin/ggrep'

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
    shortcut 'cut' '/usr/local/bin/gcut'
    shortcut 'head' '/usr/local/bin/ghead'
    shortcut 'readlink' '/usr/local/bin/greadlink'
    shortcut 'realpath' '/usr/local/bin/grealpath'
    shortcut 'sed' '/usr/local/bin/gsed'
    shortcut 'tail' '/usr/local/bin/gtail'
fi

export JOSH_INIT=1
