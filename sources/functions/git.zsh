GIT_ROOT='git rev-parse --quiet --show-toplevel'
GIT_BRANCH='git rev-parse --quiet --abbrev-ref HEAD'
GIT_BRANCH2='git name-rev --name-only HEAD | cut -d "~" -f 1'
GIT_HASH='git rev-parse --quiet --verify HEAD'
GIT_LATEST='git log --all -n 1 --pretty="%H"'

# https://git-scm.com/docs/git-status - file statuses
# https://stackoverflow.com/questions/53298546/git-file-statuses-of-files

local THIS_DIR=`dirname "$(readlink -f "$0")"`
local GIT_LIST_NEW="$THIS_DIR/scripts/git_list_new.sh"
local GIT_DIFF_FROM_TAG="$THIS_DIR/scripts/git_diff_from_tag.sh"
local GIT_HASH_FROM_TAG="$THIS_DIR/scripts/git_hash_from_tag.sh"
local GIT_LIST_BRANCHES="$THIS_DIR/scripts/git_list_branches.sh"
local GIT_TAG_FROM_STR="$THIS_DIR/scripts/git_tag_from_str.sh"

local GIT_LIST_TAGS="$THIS_DIR/scripts/git_list_tags.sh"
local GIT_LIST_CHANGED='git ls-files --modified `git rev-parse --show-toplevel`'



git_add_created() {
    local cmd="$LISTER_FILE --paging='always' {}"
    while true; do
        local files="$(zsh "$GIT_LIST_NEW" | sort | uniq | \
            fzf \
                --pointer=" " --marker="*" --multi --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview="$cmd" \
            | sort | sed -z 's/\n/ /g' | awk '{$1=$1};1'
        )"

        if [[ "$BUFFER" != "" ]]; then
            local prefix="$BUFFER && "
        else
            local prefix=""
        fi

        if [[ "$files" != "" ]]; then
            local branch="${1:-`sh -c "$GIT_BRANCH"`}"
            LBUFFER="$prefix git add $files && gmm '$branch: "
            RBUFFER="'"
            local ret=$?
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N git_add_created


git_add_changed() {
    # https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1
    local differ="git diff --color=always -- {} | $DELTA"
    while true; do
        local files="$(echo "$GIT_LIST_CHANGED" | zsh | sort | uniq | \
            fzf \
                --pointer=" " --marker="*" --multi --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview="$differ" \
            | sort | sed -z 's/\n/ /g' | awk '{$1=$1};1'
        )"

        if [[ "$BUFFER" != "" ]]; then
            local prefix="$BUFFER && "
        else
            local prefix=""
        fi

        if [[ "$files" != "" ]]; then
            local branch="${1:-`sh -c "$GIT_BRANCH"`}"
            LBUFFER="$prefix git add $files && gmm '$branch: "
            RBUFFER="'"
            local ret=$?
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N git_add_changed


git_restore_changed() {
    local cmd="git diff --color=always -- {} | $DELTA"
    while true; do
        local files="$(echo "$GIT_LIST_CHANGED" | zsh | sort | uniq | \
            fzf \
                --pointer=" " --marker="*" --multi --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview="$cmd" \
            | sort | sed -z 's/\n/ /g' | awk '{$1=$1};1'
        )"

        if [[ "$BUFFER" != "" ]]; then
            local prefix="$BUFFER && "
        else
            local prefix=""
        fi

        if [[ "$files" != "" ]]; then
            # LBUFFER="git restore $files"
            LBUFFER="$prefix git checkout -- $files"
            local ret=$?
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N git_restore_changed


show_all_files() {
    local cmd="$LISTER_FILE --paging='always' {}"
    eval "fd \
        --color always \
        --type file --follow --hidden \
        --exclude .git/ \
        --exclude '*.pyc' \
        --exclude node_modules/ \
        --glob \"*\" . " | \
    fzf \
        --pointer=" " --marker="*" --margin=0,0,0,0 \
        --info='inline' --ansi --extended --filepath-word --no-mouse \
        --bind='esc:cancel' \
        --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
        --bind='home:preview-up' --bind='end:preview-down' \
        --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
        --bind='alt-w:toggle-preview-wrap' \
        --bind="alt-bs:toggle-preview" \
        --preview-window="right:89:noborder" \
        --preview="$LISTER_FILE --terminal-width=\$FZF_PREVIEW_COLUMNS {}" \
        --bind="enter:execute($cmd)"

    local ret=$?
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}
zle -N show_all_files

git_branch_history() {
    # https://git-scm.com/docs/git-show
    # https://git-scm.com/docs/pretty-formats

    local branch="$(echo "$GIT_BRANCH" | zsh)"

    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --width $COLUMNS| less -R"
        else
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --paging='always'"
        fi
        eval "git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' --first-parent $branch" | awk '{print NR,$0}' | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview=$cmd \
                --bind="enter:execute($cmd)"
        local ret=$?
        zle redisplay
        typeset -f zle-line-init >/dev/null && zle zle-line-init
        return $ret
    fi
}
zle -N git_branch_history


git_all_history() {
    # https://git-scm.com/docs/git-show
    # https://git-scm.com/docs/pretty-formats

    local branch="$(echo "$GIT_BRANCH" | zsh)"

    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --width $COLUMNS| less -R"
        else
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --paging='always'"
        fi
        eval "git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' --all --graph" | grep -P '([0-9a-f]{8})' | awk '{print NR,$0}' | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview=$cmd \
                --bind="enter:execute($cmd)"
        local ret=$?
        zle redisplay
        typeset -f zle-line-init >/dev/null && zle zle-line-init
        return $ret
    fi
}
zle -N git_all_history


git_file_history() {
    local diff_file="'git show --diff-algorithm=histogram --format=\"%C(yellow)%h %ad %an <%ae>%n%s%C(black)%C(bold) %cr\" \$0 --"
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        while true; do
            local file="$(git ls-files | \
                fzf \
                    --pointer=" " --marker="*" --margin=0,0,0,0 \
                    --info='inline' --ansi --extended --filepath-word --no-mouse \
                    --bind='esc:cancel' \
                    --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                    --bind='home:preview-up' --bind='end:preview-down' \
                    --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                    --bind='alt-w:toggle-preview-wrap' \
                    --bind="alt-bs:toggle-preview" \
                    --preview-window="right:89:noborder" \
                    --preview="$LISTER_FILE --terminal-width=\$FZF_PREVIEW_COLUMNS {}" \
                | sort | sed -z 's/\n/ /g' | awk '{$1=$1};1'
            )"
            if [[ "$file" == "" ]]; then
                zle redisplay
                zle reset-prompt
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return 0
            fi

            if [ $OS_TYPE = "BSD" ]; then
                local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -l bash -c $diff_file $file' | $DELTA --width $COLUMNS | less -R"
            else
                local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -l bash -c $diff_file $file' | $DELTA --paging='always'"
            fi

            eval "git log --color=always --graph --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' $file $@" | \
                fzf +s +m --tiebreak=length,index \
                    --info='inline' --ansi --extended --filepath-word --no-mouse \
                    --bind='esc:cancel' \
                    --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                    --bind='home:preview-up' --bind='end:preview-down' \
                    --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                    --margin=0,0,0,0 \
                    --bind='alt-w:toggle-preview-wrap' \
                    --bind="alt-bs:toggle-preview" \
                    --preview-window="right:89:noborder" \
                    --preview=$cmd \
                    --bind="enter:execute($cmd)"
        done
    fi
}
zle -N git_file_history


git_checkout_tag() {
    local latest="$(echo "$GIT_LATEST" | zsh)"

    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --width $COLUMNS | less -R"
        else
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --paging='always'"
        fi

        local commit="$(echo "$latest" | zsh $GIT_LIST_TAGS | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview=$cmd | zsh $GIT_TAG_FROM_STR
        )"

        if [[ "$commit" == "" ]]; then
            zle reset-prompt
            return 0
        else
            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && git checkout $commit"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            else
                git checkout $commit 2>/dev/null 1>/dev/null
                zle reset-prompt
                return 0
            fi
        fi
    fi
}
zle -N git_checkout_tag


git_fetch_branch() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --width $COLUMNS | less -R"
        else
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --paging='always'"
        fi

        local branches="$(git ls-remote -h origin | sed -r 's%^[a-f0-9]{40}\s+refs/heads/%%g' | sort | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse --multi \
                --bind='esc:cancel' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'
        )"
        local track="git branch -f --track $(echo "$branches" | sed -r "s% % \&\& git branch -f --track %g")"

        if [[ "$branches" == "" ]]; then
            zle reset-prompt
            return 0
        else
            local cmd="$track && git fetch origin $branches"

            if [[ $branches != *" "* ]]; then
                local cmd="$cmd && git checkout $branches"
            fi

            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && $cmd"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            else
                echo $cmd
                echo $cmd | zsh
                zle reset-prompt
                return 0
            fi
        fi
    fi
}
zle -N git_fetch_branch


git_delete_branch() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --width $COLUMNS | less -R"
        else
            local cmd="echo {} | zsh $GIT_DIFF_FROM_TAG | $DELTA --paging='always'"
        fi

        local branches="$(git ls-remote -h origin | sed -r 's%^[a-f0-9]{40}\s+refs/heads/%%g' | sort | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse --multi \
                --bind='esc:cancel' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'
        )"

        if [[ "$branches" == "" ]]; then
            zle reset-prompt
            return 0
        else
            local cmd="git push origin --delete $branches && git branch -D $branches"

            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && $cmd"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            else
                LBUFFER="$cmd"
                zle reset-prompt
                return 0
            fi
        fi
    fi
}
zle -N git_delete_branch


git_checkout_branch() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | cut -c 3- | cut -d ' ' -f 1 | $DELTA --width $COLUMNS | less -R"
        else
            local cmd="echo {} | cut -c 3- | cut -d ' ' -f 1 | xargs -I% git diff % | $DELTA --paging='always'"
        fi

        local commit="$(zsh $GIT_LIST_BRANCHES | \
            fzf \
                --pointer=" " --marker="*" --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview="$cmd" | cut -c 3- | cut -d ' ' -f 1
        )"

        if [[ "$commit" == "" ]]; then
            zle reset-prompt
            return 0
        else
            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && git checkout $commit"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            else
                git checkout $commit 2>/dev/null 1>/dev/null
                zle reset-prompt
                return 0
            fi
        fi
    fi
}
zle -N git_checkout_branch


git_checkout_commit() {
    local branch="$(echo "$GIT_BRANCH" | zsh)"

    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --width $COLUMNS| less -R"
        else
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --paging='always'"
        fi

        local result="$(git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' --first-parent $branch | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word --no-mouse \
                --bind='esc:cancel' \
                --bind='pgup:preview-page-up' --bind='pgdn:preview-page-down'\
                --bind='home:preview-up' --bind='end:preview-down' \
                --bind='shift-up:half-page-up' --bind='shift-down:half-page-down' \
                --margin=0,0,0,0 \
                --bind='alt-w:toggle-preview-wrap' \
                --bind="alt-bs:toggle-preview" \
                --preview-window="right:89:noborder" \
                --preview=$cmd | cut -d ' ' -f 1
        )"

        if [[ "$result" == "" ]]; then
            zle reset-prompt
            return 0
        else
            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && git checkout $result"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            else
                git checkout $result 2>/dev/null
                zle reset-prompt
                return 0
            fi
        fi
    fi
}
zle -N git_checkout_commit


function sfet() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git fetch origin $branch
}
function spll() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git pull origin $branch
}
function sfet() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    if [ "$branch" = "" ]
    then
        echo " - Branch required."
        return 1
    fi
    git fetch origin $branch
    git fetch --tags --all
}
function sall() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    if [ "$branch" = "" ]
    then
        echo " - Branch required."
        return 1
    fi
    sfet $branch
    git reset --hard origin/$branch
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

function sfm() {
    if [ "$1" = "" ]
    then
        echo " - Branch name required."
        return 1
    fi
    git fetch origin $1 && git merge $1
}

function sbrm() {
    if [ "$1" = "" ]
    then
        echo " - Branch name required."
        return 1
    fi
    git branch -D $1 && git push origin --delete $1
}

function sbmv() {
    if [ "$1" = "" ]
    then
        echo " - Branch name required."
        return 1
    fi
    local branch="${2:-`sh -c "$GIT_BRANCH"`}"
    git branch -m $branch $1 && git push origin :$branch $1
}

function stag() {
    if [ "$1" = "" ]
    then
        echo " - Tag required."
        return 1
    fi
    git tag -a $1 -m "$1" && git push --tags
}

function stag-() {
    if [ "$1" = "" ]
    then
        echo " - Tag required."
        return 1
    fi
    git tag -d "$1" && git push --delete origin "$1"
}

alias gmm='git commit -m'
alias gdd='git diff --name-only'
alias gdr='git ls-files --modified `git rev-parse --show-toplevel`'

bindkey "^a" git_add_created
bindkey "\ea" git_add_changed
bindkey "\e^a" git_restore_changed

bindkey "^q" git_checkout_commit
bindkey "\eq" git_checkout_branch
bindkey "\e^q" git_checkout_tag

bindkey "^[Q" git_fetch_branch
bindkey "^[S" git_delete_branch

bindkey "^s" git_file_history
bindkey "\es" git_branch_history
bindkey "\e^s" git_all_history

# bindkey "^[^M" accept-and-hold # Esc-Enter
