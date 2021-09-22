if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -n "$JOSH_DEST" ]; then
        VERBOSE=1

    elif [ -z "$JOSH" ]; then
        source "`dirname $0`/boot.sh"
        VERBOSE=0
    fi
fi


if [ "$HTTP_GET" ]; then
    echo

elif [ "`lookup curl`" ]; then
    export HTTP_GET="`lookup curl` -fsSL"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET" 1>&2

elif [ "`lookup wget`" ]; then
    export HTTP_GET="`lookup wget` -qO -"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET" 1>&2

elif [ "`lookup fetch`" ]; then
    export HTTP_GET="`lookup fetch` -qo - "
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using fetch: $HTTP_GET" 1>&2

elif [ "`lookup http`" ]; then
    export HTTP_GET="`lookup http` -FISb"
    [ "$VERBOSE" -eq 1 ] && \
    echo " * using httpie `http --version`: $HTTP_GET" 1>&2

else
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 1
fi


if [ -n "$(uname | grep -i freebsd)" ]; then
    export JOSH_GREP='/usr/local/bin/grep'
    export JOSH_LS='/usr/local/bin/gnuls'
    export JOSH_READLINK='/usr/local/bin/greadlink'
    export JOSH_REALPATH='/usr/local/bin/grealpath'
    export JOSH_SED='/usr/local/bin/gsed'
    export OSTYPE="BSD"


elif [ -n "$(uname | grep -i darwin)" ]; then
    export JOSH_GREP='/usr/local/bin/ggrep'
    export JOSH_LS='/usr/local/bin/gls'
    export JOSH_READLINK='/usr/local/bin/greadlink'
    export JOSH_REALPATH='/usr/local/bin/grealpath'
    export JOSH_SED='/usr/local/bin/gsed'
    export OSTYPE="MAC"
    export PATH="$PATH:/Library/Apple/usr/bin"

else
    export JOSH_GREP="`lookup grep`"
    export JOSH_LS="`lookup ls`"
    export JOSH_READLINK="`lookup readlink`"
    export JOSH_REALPATH="`lookup realpath`"
    export JOSH_SED="`lookup sed`"

    if [ -n "$(uname | grep -i linux)" ]; then
        export OSTYPE="LINUX"
    else
        echo " - ERROR: unsupported OS!"
        export OSTYPE="UNKNOWN"
    fi
fi
