
if [[ "$OSTYPE" == "freebsd"* ]]; then
    export JOSH_GREP='/usr/local/bin/grep'
    export JOSH_LS='/usr/local/bin/gnuls'
    export JOSH_REALPATH='/usr/local/bin/grealpath'
    export JOSH_SED='/usr/local/bin/gsed'
    export OS_TYPE="BSD"

else
    export JOSH_GREP=`which -p grep`
    export JOSH_LS=`which -p ls`
    export JOSH_REALPATH=`which -p realpath`
    export JOSH_SED=`which -p sed`
    export OS_TYPE="LINUX"
fi
# TODO: checks for -f

[ -f "`which -p bat`" ] && export JOSH_BAT="`which -p bat`"
[ -f "`which -p delta`" ] && export JOSH_DELTA="`which -p delta`"
[ -f "`which -p http`" ] && export JOSH_HTTP="`which -p http`"
[ -f "`which -p viu`" ] && export JOSH_VIU="`which -p viu`"
