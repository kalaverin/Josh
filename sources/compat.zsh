export JOSH_DELTA=`which -p delta`

if [[ "$OSTYPE" == "freebsd"* ]]; then
    export JOSH_LS='/usr/local/bin/gnuls'
    export JOSH_SED='/usr/local/bin/gsed'
    export JOSH_GREP='/usr/local/bin/grep'
    export JOSH_REALPATH='/usr/local/bin/grealpath'

    export OS_TYPE="BSD"

else
    export JOSH_LS=`which -p ls`
    export JOSH_SED=`which -p sed`
    export JOSH_GREP=`which -p grep`
    export JOSH_REALPATH=`which -p realpath`

    export OS_TYPE="LINUX"
fi

export DELTA="delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"

export JOSH_HTTP=`which -p http`
