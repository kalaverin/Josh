GIT_ROOT='git rev-parse --quiet --show-toplevel'
GIT_BRANCH='git rev-parse --quiet --abbrev-ref HEAD'


git_add_changed() {
    # https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1
    local differ="git diff --color=always -- {} | $DELTA"
    while true; do
        local files="$(echo "$FORGIT_CMD_DIFF" | sh | \
            fzf \
                --pointer=" " --marker="*" --multi --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word \
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
        if [[ "$files" != "" ]]; then
            local branch="${1:-`sh -c "$GIT_BRANCH"`}"
            LBUFFER="git add $files && gmm '$branch "
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
        local files="$(echo "$FORGIT_CMD_DIFF" | sh | \
            fzf \
                --pointer=" " --marker="*" --multi --margin=0,0,0,0 \
                --info='inline' --ansi --extended --filepath-word \
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
        if [[ "$files" != "" ]]; then
            # LBUFFER="git restore $files"
            LBUFFER="git checkout -- $files"
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
        --info='inline' --ansi --extended --filepath-word \
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

git_history() {
    # https://git-scm.com/docs/git-show
    # https://git-scm.com/docs/pretty-formats
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        if [ $OS_TYPE = "BSD" ]; then
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --width $COLUMNS| less -R"
        else
            local cmd="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I% git show --diff-algorithm=histogram % | $DELTA --paging='always'"
        fi
        eval "git log --color=always --graph --format='%C(auto)%h%d %s %C(black)%C(bold)%ae, %cr' $@" | \
            fzf +s +m --tiebreak=length,index \
                --info='inline' --ansi --extended --filepath-word \
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
zle -N git_history

git_file_history() {
    local diff_file="'git show --diff-algorithm=histogram --format=\"%C(yellow)%h %ad %an <%ae>%n%s%C(black)%C(bold) %cr\" \$0 --"
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        while true; do
            local file="$(git ls-files | \
                fzf \
                    --pointer=" " --marker="*" --margin=0,0,0,0 \
                    --info='inline' --ansi --extended --filepath-word \
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

            eval "git log --color=always --graph --format='%C(auto)%h%d %s %C(black)%C(bold)%ae, %cr' $file $@" | \
                fzf +s +m --tiebreak=length,index \
                    --info='inline' --ansi --extended --filepath-word \
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

function sfet() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git fetch origin $branch
}
function spll() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    git pull origin $branch
}
function sall() {
    local branch="${1:-`sh -c "$GIT_BRANCH"`}"
    if [ "$branch" = "" ]
    then
        echo " - Branch required."
        return 1
    fi
    git fetch origin $branch
    git fetch --tags --all
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

function stag() {
    if [ "$1" = "" ]
    then
        echo " - Tag required."
        return 1
    fi
    git tag -a $1 -m "$1" && git push --tags
}

alias gmm='git commit -m'
alias gdd='git diff --name-only'
alias gdr='git ls-files --modified `git rev-parse --show-toplevel`'

bindkey "\e^a" git_restore_changed
bindkey "\ea" git_add_changed

bindkey "\e^s" git_history
bindkey "^s" show_all_files
bindkey "\es" git_file_history
