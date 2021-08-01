REAL="~"
REAL=$(sh -c "echo $REAL")
export REAL="$(realpath $REAL)"

export ZSH="$REAL/.josh"
export JOSH="$ZSH/custom/plugins/josh"

if [ "$HTTP_GET" ]; then
    echo

elif [ "`which curl`" ]; then
    export HTTP_GET="`which curl` -fsSL"
    # echo " * using curl `curl --version | head -n 1 | awk '{print $2}'`: $HTTP_GET" 1>&2

elif [ "`which wget`" ]; then
    export HTTP_GET="`which wget` -qO -"
    # echo " * using wget `wget --version | head -n 1 | awk '{print $3}'`: $HTTP_GET" 1>&2

elif [ "`which fetch`" ]; then
    export HTTP_GET="`which fetch` -qo - "
    # echo " * using fetch: $HTTP_GET" 1>&2

elif [ "`which http`" ]; then
    export HTTP_GET="`which http` -FISb"
    # echo " * using httpie `http --version`: $HTTP_GET" 1>&2

else
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 1
fi
