
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

if [ "`which -p delta`" ]; then
    export JOSH_DELTA="`which -p delta`"
    export DELTA="$JOSH_DELTA --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"
    [ "`which -p bat`" ] && export DELTA="$DELTA --pager `which -p bat`"
fi

export JOSH_HTTP=`which -p http`
