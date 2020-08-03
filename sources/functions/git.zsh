GIT_ROOT='git rev-parse --quiet --show-toplevel'
GIT_BRANCH='git rev-parse --quiet --abbrev-ref HEAD'

alias gmm='git commit -m'
alias gdd='git diff --name-only'
alias gdr='git ls-files --modified `git rev-parse --show-toplevel`'

function sfet() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git fetch origin $branch
}
function spll() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git pull origin $branch
}
function spsh() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git push origin $branch
}
function smer() {
    if [ "$1" = "" ]
    then
        echo " - Branch name required."
        return 1
    fi
    git merge origin $1
}
function sbrm() {
    if [ "$1" = "" ]
    then
        echo " - Branch name required."
        return 1
    fi
    git branch -D $1 && git push origin --delete $1
}
