unalias _
if [[ "$OSTYPE" == "freebsd"* ]]; then
    alias ls='/usr/local/bin/gnuls -vaAF --color'
    alias ri='/usr/local/bin/grep -rnH --color=auto'
    alias sed='/usr/local/bin/gsed'
    alias realpath='/usr/local/bin/grealpath'

    export DELTA="delta --commit-style plain --file-style plain --hunk-style plain --highlight-removed"

else
    alias ls='ls -vaAF --color'
    alias ri='grep -rnH --color=auto'

    export DELTA="delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate"
fi

if [ -n "$(uname -v | grep -i debian)" ]; then
    alias fd='fdfind'
fi
