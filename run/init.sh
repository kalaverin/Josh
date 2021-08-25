if [ "$HOME" ] && [ -d "$HOME" ]; then
    export REAL="$HOME"
else
    export REAL="~"
fi

if [ -f "`which -p realpath`" ]; then
    export REAL="`realpath -q $REAL`"
elif [ -f "`which -p readlink`" ]; then
    export REAL="`readlink -qf $REAL`"
else
    export REAL="`dirname $REAL`/`basename $REAL`"
fi

export ZSH="$REAL/.josh"
export JOSH="$ZSH/custom/plugins/josh"

if [ "$HTTP_GET" ]; then
    echo

elif [ "`which -p curl`" ]; then
    export HTTP_GET="`which -p curl` -fsSL"
    # echo " * using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET" 1>&2

elif [ "`which -p wget`" ]; then
    export HTTP_GET="`which -p wget` -qO -"
    # echo " * using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET" 1>&2

elif [ "`which -p fetch`" ]; then
    export HTTP_GET="`which -p fetch` -qo - "
    # echo " * using fetch: $HTTP_GET" 1>&2

elif [ "`which -p http`" ]; then
    export HTTP_GET="`which -p http` -FISb"
    # echo " * using httpie `http --version`: $HTTP_GET" 1>&2

else
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 1
fi
