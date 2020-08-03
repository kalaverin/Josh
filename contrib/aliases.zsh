unalias _

if [[ "$OSTYPE" == "freebsd"* ]]; then
    ls_bin='/usr/local/bin/gnuls'
    if [[ ! -f $ls_bin ]]; then
        echo "Try install GNU ls: pkg install gnuls"
        return
    fi
    alias ls='gnuls -a --color'
    alias ri='/usr/local/bin/grep -rnH --color=auto'
    alias sed='/usr/local/bin/gsed'
    alias realpath='/usr/local/bin/grealpath'
else
    alias ri='grep -ri'
    alias ls='ls -vAF --color'
fi

if [ -n "$(uname -v | grep -i debian)" ]; then
    alias fd='fdfind'
fi
alias cpdir='rsync --archive --links --times'

alias mv='nocorrect mv'
alias ln='nocorrect ln'
alias cp='nocorrect cp -iR'
alias rm='nocorrect rm'
alias ps='nocorrect ps'
alias tt='tail -f -n 1000'

alias ag='ag --noaffinity --ignore .git/ --ignore node_modules/ --ignore "lib/python*/site-packages/" --ignore "__snapshots__/" --ignore "*.pyc" --ignore "*.po" --ignore "*.svg" --literal --stats -W 140'

alias gmm='git commit -m'
alias gdd='git diff --name-only'
alias gdr='git ls-files --modified `git rev-parse --show-toplevel`'

vact() {
    source $1/bin/activate
}
alias dact='deactivate'

alias -g L='| grep -i'
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g GL="awk '{\$1=\$1};1' | sed -z 's/\n/ /g' | awk '{\$1=\$1};1'"

svc() {
    service $*
}

fchmod() {
    find $2 -type f -not -perm $1 -exec chmod $1 {} \;
}
dchmod() {
    find $2 -type d -not -perm $1 -exec chmod $1 {} \;
}
rchgrp() {
    find $2 ( -not -group $1 ) -print -exec chgrp $1 {} ;
}
lst() {
    tree -F -f -i $1 | grep -v '[/]$'
}
look() {
    nocorrect find . -type f | xargs -n 1 grep -nHi "$*"
}
lg() {
    nocorrect la $2 | grep -i $1
}
function mkcd {
    mkdir "$1" && cd "$1"
}

kimport() {
    gpg --recv-key $1 && gpg --export $1 | apt-key add -
}
pir() {
    cat $1 | xargs -n 1 pip install
}

w() {
    sh -c "$READ_URI \"http://cheat.sh/`urlencode $@`\""
}
q() {
    sh -c "$READ_URI \"http://cheat.sh/~`urlencode $@`\""
}

commit () {
    RBUFFER=`sh -c "$READ_URI http://whatthecommit.com/index.txt"`${RBUFFER}
    zle end-of-line
}
last-dir() {
    local $directory="${1:-.}"
    find $directory -type d -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1
}


alias http='http --verify no'
function agent {
    eval `ssh-agent` && ssh-add
}

function ven {
    local name="${1:-main}"
    local last_path="`pwd`"
    wd env
    vact $name
    cd $last_path
}
function tenv {
    local vers="2.7"

    if [ "$1" != "" ]
    then
        if [[ $1 =~ ^[0-9]\.[0-9]$ ]]
        then
            local vers="$1"
        else
            local name="$1"
        fi
    fi

    if [ "$2" != "" ]
    then
        if [[ $2 =~ ^[0-9]\.[0-9]$ ]]
        then
            local vers="$2"
        else
            local name="$2"
        fi
    fi

    if [ -f "/tmp/env/$name/bin/activate" ]
    then
        source /tmp/env/$name/bin/activate
    else
        local pbin="/usr/bin/python$vers"
        if [ ! -f "$pbin" ]
        then
            echo " ! not exists: $pbin"
            return 1
        fi

        if [ ! -d "/tmp/env" ]
        then
            mkdir /tmp/env
        fi
        local lwd="`pwd`"
        cd /tmp/env

        if [ "$name" = "" ]
        then
            local name="$(mktemp -d XXXX)"
        fi

        # echo " Go: $vers to $name"
        virtualenv --python=$pbin $name
        source $name/bin/activate
        cd $lwd
    fi
}

GIT_ROOT='git rev-parse --quiet --show-toplevel'
GIT_BRANCH='git rev-parse --quiet --abbrev-ref HEAD'

function sfet() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git fetch origin $branch
}

function smer() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git merge origin $branch
}

function spush() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git push origin $branch
}

function spull() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git pull origin $branch
}

function sbrm() {
    if [ "$1" = "" ]
    then
        echo "- Branch name required."
        return 1
    fi
    branch="$1"
    git branch -D $branch && git push origin --delete $branch
}
