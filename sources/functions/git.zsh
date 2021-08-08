# https://git-scm.com/docs/git-show
# https://git-scm.com/docs/pretty-formats
# https://git-scm.com/docs/git-status - file statuses
# https://stackoverflow.com/questions/53298546/git-file-statuses-of-files
# https://github.com/romkatv/gitstatus

# for ripgrep: --no-messages --no-filename --max-count

GIT_ROOT='git rev-parse --quiet --show-toplevel'
GIT_BRANCH='git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null'
GIT_BRANCH2='git name-rev --name-only HEAD | cut -d "~" -f 1'
GIT_HASH='git rev-parse --quiet --verify HEAD'
GIT_LATEST='git log --all -n 1 --pretty="%H"'


local THIS_DIR=`dirname "$(readlink -f "$0")"`
local GIT_DIFF_FROM_TAG="$THIS_DIR/scripts/git_diff_from_tag.sh"
local GIT_HASH_FROM_TAG="$THIS_DIR/scripts/git_hash_from_tag.sh"
local GIT_LIST_BRANCHES_EXCEPT_THIS="$THIS_DIR/scripts/git_list_branches_except_this.sh"
local GIT_LIST_BRANCHES="$THIS_DIR/scripts/git_list_branches.sh"
local GIT_LIST_BRANCH_FILES="$THIS_DIR/scripts/git_list_branch_files.sh"
local GIT_TAG_FROM_STR="$THIS_DIR/scripts/git_tag_from_str.sh"
local GIT_TAG_FROM_STR="$THIS_DIR/scripts/git_tag_from_str.sh"
local GIT_SEARCH_SETUPCFG="$THIS_DIR/scripts/git_search_setupcfg.sh"

local GIT_LIST_TAGS="$THIS_DIR/scripts/git_list_tags.sh"

# --stat=\$FZF_PREVIEW_COLUMNS
local ARGS_DIFF="--color=always --stat --patch --diff-algorithm=histogram"
local DIFF="git diff $ARGS_DIFF"

local UNIQUE_SORT="runiq - | proximity-sort ."
local LINES_TO_LINE="sd '\n' ' ' | awk '{\$1=\$1};1'"
local GIT_STATUS_MARKS='sd "^( )" "." | sd "^(.)( )" "$1."'

local FZF_JUMPS='0123456789abcdefghijklmnopqrstuvwxyz'
local FZF="fzf --ansi --extended --info='inline' --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' --tiebreak=length,index --jump-labels=\"$FZF_JUMPS\" --bind='alt-space:jump-accept' --bind='alt-w:toggle-preview-wrap' --bind='ctrl-c:abort' --bind='ctrl-q:abort' --bind='end:preview-down' --bind='esc:cancel' --bind='home:preview-up' --bind='pgdn:preview-page-down' --bind='pgup:preview-page-up' --bind='shift-down:half-page-down' --bind='shift-up:half-page-up' --color=\"$FZF_THEME\""


git_root() {
    local result=$(realpath `$SHELL -c "$GIT_ROOT"`)
    [ "$result" ] && echo "$result"
}

git_current_hash() {
    local result="`git rev-parse --quiet --verify HEAD 2>/dev/null`"
    [ "$result" ] && echo "$result"
}

git_current_branch() {
    local result="`git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null`"
    if [ "$result" = "HEAD" ]; then
        if [ ! "`git name-rev --name-only HEAD 2>&1 | grep -Pv '^(Could not get sha1)'`" ]; then
            echo " - empty repository `git_root` without any commits?" >&2
            local result="`git symbolic-ref --short HEAD`"
        fi
    fi
    [ "$result" ] && echo "$result"
}

git_checkout_branch() {
    [ ! "$1" ] && return 1
    local root="`git_root`"
    [ ! "$root" ] && return 1

    local cmd="git fetch origin \"$1\":\"$1\" && is_repository_clean && git checkout --force --quiet $1 && git reset --hard $1 && git pull origin $1"
    run_show "$cmd"
    return $?
}

git_widget_add() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    local cwd="`pwd`"
    local select='git status --short --verbose --no-ahead-behind'

    while true; do
        local value="$(
            $SHELL -c "$select | $GIT_STATUS_MARKS \
            | $FZF \
            --multi --nth=2.. --with-nth=1.. \
            --filepath-word \
            --preview=\"$DIFF $branch -- {2} | $DELTA\" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt='git add >  ' \
            | tabulate -i 2 | sort --human-numeric-sort | $UNIQUE_SORT \
            | xargs -n 1 realpath --quiet --relative-to=$cwd 2>/dev/null \
            | $LINES_TO_LINE")"

        if [ ! "$value" ]; then
            zle reset-prompt
            local retval="0"
            break
        fi

        if [ ! "$BUFFER" ]; then
            local command=" git add"
        else
            local command="$BUFFER && git add"
        fi

        local conflicts=$(git status --porcelain --branch | grep -P '^(AA|UU)' | tabulate -i 2)
        if [ "$conflicts" ]; then
            LBUFFER="$command $value "
            RBUFFER=''
        else
            LBUFFER="$command $value && git commit -m \"$branch: "
            RBUFFER='"'
        fi
        zle redisplay
        local retval="$?"
        break
    done
    return "$retval"
}
zle -N git_widget_add


git_widget_checkout_modified() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    local cwd="`pwd`"
    local select='git status --short --verbose --no-ahead-behind --untracked-files=no'

    while true; do
        local value="$(
            $SHELL -c "$select | $GIT_STATUS_MARKS \
            | $FZF \
            --multi --nth=2.. --with-nth=1.. \
            --filepath-word \
            --preview=\"$DIFF $branch -- {2} | $DELTA\" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt=\"checkout to $branch >  \" \
            | tabulate -i 2 | sort --human-numeric-sort | $UNIQUE_SORT \
            | xargs -n 1 realpath --quiet --relative-to=$cwd 2>/dev/null \
            | $LINES_TO_LINE")"

        if [ ! "$value" ]; then
            zle reset-prompt
            local retval="0"
            break
        fi

        [ "$BUFFER" != "" ] && local command="$BUFFER &&"
        LBUFFER="$command git checkout $branch -- $value"

        zle redisplay
        local retval=130
        break
    done
    return "$retval"
}
zle -N git_widget_checkout_modified


git_widget_conflict_solver() {
    local root="`git_root`"
    [ ! "$root" ] && return 1
    local branch="`git_current_branch`"

    local select='git status \
                    --porcelain \
                    --branch \
                    | grep -P "^(AA|UU)" \
                    | tabulate -i 2'

    local unroot="cut -c $((${#root} + 2))-"
    local rootate="sed -r 's:\s\b: $root/:g' | xargs -I@ echo $root/@"

    while true; do
        local value="$(
            $SHELL -c "$select | $rootate | $LINES_TO_LINE \
            | xargs rg --fixed-strings --files-with-matches '<<<<<<<' | $unroot | $UNIQUE_SORT \
            | $FZF \
            --filepath-word \
            --prompt=\"solving in $branch >  \" \
            --preview=\"$DIFF $branch -- $root/{} | $DELTA\" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            | $UNIQUE_SORT | $LINES_TO_LINE | $rootate")"

        if [ "$value" = "" ]; then
            break
        fi
        local row=$(grep -P --line-number --max-count=1 "^(>>>>>>> .+)$" $value | tabulate -d ':' -i 1)
        $EDITOR $value +$row
        continue
    done
    return 0
}
zle -N git_widget_conflict_solver


git_widget_select_commit_then_files_checkout() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GIT_BRANCH" | $SHELL)}
        local commit="$(git_list_commits "$branch" | pipe_remove_dots_and_spaces | pipe_numerate | \
            fzf \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump' \
                --color="$FZF_THEME" \
                --preview-window="left:`get_preview_width`:noborder" \
                --prompt="$branch: select commit >  " \
                --preview="echo {} | head -1 | grep -o '[a-f0-9]\{7,\}$' | xargs -I% git diff --color=always --shortstat --patch --diff-algorithm=histogram $branch % | $DELTA --paging='always'" | head -1 | grep -o '[a-f0-9]\{7,\}$'
        )"
        if [[ "$commit" == "" ]]; then
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return 0
        fi

        local root=$(realpath `$SHELL -c "$GIT_ROOT"`)
        local differ="echo {} | xargs -I% git diff --color=always --shortstat --patch --diff-algorithm=histogram $branch $commit -- $root/% | $DELTA"
        while true; do
            local files="$(git diff --name-only $branch $commit | proximity-sort . | \
                fzf \
                    --ansi --extended --info='inline' \
                    --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                    --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                    --bind='alt-w:toggle-preview-wrap' \
                    --bind='ctrl-c:abort' \
                    --bind='ctrl-q:abort' \
                    --bind='end:preview-down' \
                    --bind='esc:cancel' \
                    --bind='home:preview-up' \
                    --bind='pgdn:preview-page-down' \
                    --bind='pgup:preview-page-up' \
                    --bind='shift-down:half-page-down' \
                    --bind='shift-up:half-page-up' \
                    --bind='alt-space:jump' \
                    --color="$FZF_THEME" \
                    --preview-window="left:`get_preview_width`:noborder" \
                    --multi \
                    --prompt="$branch: select file >  " \
                    --filepath-word --preview="$differ" \
                | proximity-sort . | sed -z 's:\n: :g' | awk '{$1=$1};1' \
                | sed -r "s:\s\b: $root/:g" | xargs -I% echo "$root/%"
            )"

            if [[ "$files" != "" ]]; then
                run_show "git checkout $commit -- $files && git reset $files > /dev/null && git diff HEAD --stat --diff-algorithm=histogram --color=always | xargs -I$ echo $"
                zle reset-prompt
                return 130
            else
                return 0
            fi
        done
    fi
}
zle -N git_widget_select_commit_then_files_checkout


git_widget_select_branch_then_commit_then_file_checkout() {
    git_widget_select_branch_with_callback git_widget_select_commit_then_files_checkout
}
zle -N git_widget_select_branch_then_commit_then_file_checkout


alias git_list_commits="git log --color=always --format='%C(auto)%D %C(reset)%s %C(black)%C(bold)%ae %cr %<(12,trunc)%H' --first-parent"
alias -g pipe_remove_dots_and_spaces="sed -re 's/(\.{2,})+$//g' | sed -re 's/(\\s+)/ /g' | sd '^\s+' ''"
alias -g pipe_numerate="awk '{print NR,\$0}'"

DELTA_FOR_COMMITS_LIST_OUT="xargs -I$ git show --find-renames --find-copies --function-context --format='format:%H %ad%n%an <%ae>%n%s' --diff-algorithm=histogram $ | $DELTA --paging='always'"

git_widget_show_commits() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GIT_BRANCH" | $SHELL)}
        eval "git_list_commits $branch" | pipe_remove_dots_and_spaces | pipe_numerate | \
            fzf \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump' \
                --color="$FZF_THEME" \
                --preview-window="left:`get_preview_width`:noborder" \
                --prompt="$branch >  " \
                --bind="enter:execute(echo {} | head -1 | grep -o '[a-f0-9]\{7,\}$' | $DELTA_FOR_COMMITS_LIST_OUT)" \
                --preview="echo {} | head -1 | grep -o '[a-f0-9]\{7,\}$' | $DELTA_FOR_COMMITS_LIST_OUT"

        local ret=$?
        if [[ "$ret" == "130" ]]; then
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        fi
    fi
}
zle -N git_widget_show_commits


git_widget_select_branch_with_callback() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local differ="echo {} | xargs -I% git diff --color=always --shortstat --patch --diff-algorithm=histogram $branch -- % | $DELTA"
        while true; do
            local branch="$($SHELL $GIT_LIST_BRANCHES | \
                fzf \
                    --ansi --extended --info='inline' \
                    --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                    --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                    --bind='alt-w:toggle-preview-wrap' \
                    --bind='ctrl-c:abort' \
                    --bind='ctrl-q:abort' \
                    --bind='end:preview-down' \
                    --bind='esc:cancel' \
                    --bind='home:preview-up' \
                    --bind='pgdn:preview-page-down' \
                    --bind='pgup:preview-page-up' \
                    --bind='shift-down:half-page-down' \
                    --bind='shift-up:half-page-up' \
                    --bind='alt-space:jump' \
                    --color="$FZF_THEME" \
                    --preview-window="left:`get_preview_width`:noborder" \
                    --prompt="select branch >  " \
                    --preview="$differ" \
                    | cut -d ' ' -f 1
            )"
            if [[ "$branch" == "" ]]; then
                zle redisplay
                zle reset-prompt
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return 0
            fi

            ${1:-git_widget_show_commits} $branch
            local ret=$?
            if [[ "$ret" == "130" ]]; then
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            fi
        done
    fi
}
zle -N git_widget_select_branch_with_callback


git_show_branch_file_commits() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local file="$2"
        local branch="$1"

        local ext="$(echo "$file" | xargs -I% basename % | grep --color=never -Po '(?<=.\.)([^\.]+)$')"

        local diff_view="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -l $SHELL -c $diff_file $file' | $DELTA --width $COLUMNS"

        local file_view="echo {} | cut -d ' ' -f 1 | xargs -I^^ git show ^^:./$file | $LISTER_FILE --paging=always"
        if [ "$ext" = "" ]; then
        else
            local file_view="$file_view --language $ext"
        fi

        eval "git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' $branch -- $file"  | sed -r 's%^(\*\s+)%%g' | \
            fzf \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump' \
                --color="$FZF_THEME" \
                --preview-window="left:`get_preview_width`:noborder" \
                --prompt="$branch:$file >  " \
                --preview="$diff_view" \
                --bind="enter:execute($file_view)"
    fi
}
zle -N git_show_branch_file_commits


git_widget_select_file_show_commits() {
    # diff full creeen at alt-bs
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GIT_BRANCH" | $SHELL)}

        local differ="$LISTER_FILE --terminal-width=\$FZF_PREVIEW_COLUMNS {}"
        local diff_file="'git show --diff-algorithm=histogram --format=\"%C(yellow)%h %ad %an <%ae>%n%s%C(black)%C(bold) %cr\" \$0 --"

        while true; do
            local file="$(git ls-files | \
                fzf \
                    --ansi --extended --info='inline' \
                    --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                    --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                    --bind='alt-w:toggle-preview-wrap' \
                    --bind='ctrl-c:abort' \
                    --bind='ctrl-q:abort' \
                    --bind='end:preview-down' \
                    --bind='esc:cancel' \
                    --bind='home:preview-up' \
                    --bind='pgdn:preview-page-down' \
                    --bind='pgup:preview-page-up' \
                    --bind='shift-down:half-page-down' \
                    --bind='shift-up:half-page-up' \
                    --bind='alt-space:jump' \
                    --color="$FZF_THEME" \
                    --preview-window="left:`get_preview_width`:noborder" \
                    --prompt="$branch: select file >  " \
                    --filepath-word --preview="$differ" \
                | sort | sed -z 's/\n/ /g' | awk '{$1=$1};1'
            )"

            if [[ "$file" == "" ]]; then
                zle redisplay
                zle reset-prompt
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return 0
            fi

            git_show_branch_file_commits $branch $file
            local ret=$?
            if [[ "$ret" != "130" ]]; then
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            fi
        done
    fi
}
zle -N git_widget_select_file_show_commits


git_widget_select_branch_then_file_show_commits() {
    git_widget_select_branch_with_callback git_widget_select_file_show_commits
}
zle -N git_widget_select_branch_then_file_show_commits


git_widget_checkout_tag() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local latest="$(echo "$GIT_LATEST" | $SHELL)"
        local current="$(echo "$GIT_BRANCH" | $SHELL)"

        local cmd="echo {} | $SHELL $GIT_DIFF_FROM_TAG | $DELTA --paging='always'"

        local differ="echo {} | cut -d ' ' -f 1 | xargs -I% git diff --color=always --stat=\$FZF_PREVIEW_COLUMNS --patch --diff-algorithm=histogram $current % | $DELTA"

        local commit="$(git log --color=always --oneline --decorate --tags --no-walk | \
            fzf \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump' \
                --preview-window="left:`get_preview_width`:noborder" \
                --color="$FZF_THEME" \
                --prompt="tag >  " \
                --preview=$cmd | $SHELL $GIT_TAG_FROM_STR \
                --preview="$differ" \
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
zle -N git_widget_checkout_tag


git_widget_checkout_branch() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    is_repository_clean >/dev/null || local state='(dirty!) '
    local differ="echo {} | tabulate -i 1 | xargs -n 1 $DIFF"
    local select='git for-each-ref \
                    --sort=-committerdate refs/heads/ \
                    --color=always \
                    --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" \
                    | awk "{\$1=\$1};1" | grep -Pv "^(\*\s+)"'
    while true; do
        local value="$(
            $SHELL -c "$select \
            | $FZF \
            --preview=\"$differ $branch | $DELTA \" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt=\"branch $state>  \" \
            | cut -d ' ' -f 1
        ")"

        if [ ! "$BUFFER" ]; then
            run_show "git checkout $value 2>/dev/null 1>/dev/null"
            local retval=$?

        elif [ "$value" ]; then
            LBUFFER="$BUFFER && git checkout $value"
        fi

        local retval=0
        break
    done
    zle reset-prompt
    return "$retval"
}
zle -N git_widget_checkout_branch


git_widget_delete_branch() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    local differ="echo {} | tabulate -i 1 | xargs -n 1 $DIFF"
    local select='git for-each-ref \
                    --sort=-committerdate refs/heads/ \
                    --color=always \
                    --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" \
                    | awk "{\$1=\$1};1" | grep -Pv "^(\*\s+)"'
    while true; do
        local value="$(
            $SHELL -c "$select \
            | $FZF \
            --multi \
            --preview=\"$differ $branch | $DELTA \" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt=\"delete branch >  \" \
            | cut -d ' ' -f 1 | $UNIQUE_SORT | $LINES_TO_LINE
        ")"

        if [ "$value" ]; then
            local cmd="git branch -D $value"
            if [ "$BUFFER" ]; then
                LBUFFER="$BUFFER && $cmd "
            else
                LBUFFER=" $cmd"
            fi
        fi
        break
    done
    zle reset-prompt
    return 0
}
zle -N git_widget_delete_branch


git_widget_fetch_branch() {
    local root="`git_root`"
    [ ! "$root" ] && return 1
    local branch="`git_current_branch`"

    local select='git ls-remote --heads --quiet origin | \
                  sd "^([0-9a-f]+)\srefs/heads/(.+)" "\$1 \$2"'

    local already_checked_out_branches="$($SHELL -c " \
        git show-ref --heads \
        | sd '^([0-9a-f]+)\srefs/heads/(.+)' '\$2' \
        | tabulate -i 1 | $LINES_TO_LINE | sd ' ' '|'
    ")"

    local filter="sort -Vk 2 | awk '{a[i++]=\$0} END {for (j=i-1; j>=0;) print a[j--] }'"
    [ "$already_checked_out_branches" ] && \
        local filter="grep -Pv '($already_checked_out_branches)$'| $filter"

    local differ="echo {} | tabulate -i 1 | xargs -i$ echo 'git diff $ 1&>/dev/null 2&>/dev/null || git fetch origin --depth=1 $ && git diff --color=always --shortstat --patch --diff-algorithm=histogram $ $branch' | $SHELL | $DELTA"

    local value="$(
        $SHELL -c "$select | $filter \
        | $FZF \
        --prompt='fetch branch >  ' \
        --preview=\"$differ\" \
        --preview-window=\"left:`get_preview_width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")"

    [ "$value" = "" ] && return 0

    local count=$(echo "$value" | wc -l)
    local value=$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')

    if [ "$count" -gt 1 ]; then
        for brnch in `echo "$value" | sd '(\s+)' '\n'`; do
            git_checkout_branch $brnch
        done
    else
        git_checkout_branch $value
    fi
    zle reset-prompt
    return $?
}
zle -N git_widget_fetch_branch


git_widget_delete_remote_branch() {
    local root="`git_root`"
    [ ! "$root" ] && return 1
    local branch="`git_current_branch`"

    local select='git ls-remote --heads --quiet origin | \
                  sd "^([0-9a-f]+)\srefs/heads/(.+)" "\$1 \$2"'

    local filter="sort -Vk 2 | awk '{a[i++]=\$0} END {for (j=i-1; j>=0;) print a[j--] }'"

    local differ="echo {} | tabulate -i 1 | xargs -i$ echo 'git diff $ 1&>/dev/null 2&>/dev/null || git fetch origin --depth=1 $ && git diff --color=always --shortstat --patch --diff-algorithm=histogram $ $branch' | $SHELL | $DELTA"

    local value="$(
        $SHELL -c "$select | $filter \
        | $FZF \
        --prompt='DELETE REMOTE BRANCH >  ' \
        --preview=\"$differ\" \
        --preview-window=\"left:`get_preview_width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")"

    [ "$value" = "" ] && return 0

    local value=$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')
    local cmd="git push origin --delete $value && git branch -D $value"

    if [[ "$BUFFER" != "" ]]; then
        LBUFFER="$BUFFER && $cmd"
        # typeset -f zle-line-init >/dev/null && zle zle-line-init
    else
        LBUFFER=" $cmd"
    fi
    zle reset-prompt
    return 0
}
zle -N git_widget_delete_remote_branch


git_widget_checkout_commit() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch="$(echo "$GIT_BRANCH" | $SHELL)"
        local differ="echo {} | head -1 | grep -o '[a-f0-9]\{7\}' | cut -d ' ' -f 1 | xargs -I% git diff --color=always --stat=\$FZF_PREVIEW_COLUMNS --patch --diff-algorithm=histogram $branch % | $DELTA"

        local result="$(git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%ae %cr' --first-parent $branch | \
            fzf \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=length,index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump' \
                --preview-window="left:`get_preview_width`:noborder" \
                --color="$FZF_THEME" \
                --prompt="commit >  " \
                --preview=$differ | cut -d ' ' -f 1
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
zle -N git_widget_checkout_commit


git_widget_merge_branch() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    is_repository_clean >/dev/null || local state='(dirty!) '
    local differ="echo {} | tabulate -i 1 | xargs -n 1 $DIFF"
    local select='git for-each-ref \
                    --sort=-committerdate refs/heads/ \
                    --color=always \
                    --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" \
                    | awk "{\$1=\$1};1" | grep -Pv "^(\*\s+)"'

    while true; do
        local value="$(
            $SHELL -c "$select \
            | $FZF \
            --preview=\"$differ $branch | $DELTA \" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt=\"$branch merge $state>  \" \
            | cut -d ' ' -f 1
        ")"

        if [ ! "$BUFFER" ]; then
            run_show "git fetch origin $value 2>/dev/null 1>/dev/null && git merge origin/$value"
            local retval=$?

        elif [ "$value" ]; then
            LBUFFER="$BUFFER && git fetch origin $value && git merge origin/$value"
        fi

        local retval=0
        break
    done
    zle reset-prompt
}
zle -N git_widget_merge_branch


function spll() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    run_show "git pull origin $branch"
}

function sfet() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    run_show "git fetch origin $branch && git fetch --tags --all"
}

function sall() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    is_repository_clean;                        [ $? -gt 0 ] && return 1
    sfet $branch 2>/dev/null;                   [ $? -gt 0 ] && return 1
    run_show "git reset --hard origin/$branch"; [ $? -gt 0 ] && return 1
    spll $branch
}

function spsh() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    run_show "git push origin $branch"
}

function sfm() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    sfet $branch 2>/dev/null; [ $? -gt 0 ] && return 1
    run_show "git merge origin/$branch"
}

function sbrm() {
    if [ "$1" = "" ]; then
        echo " - Branch name required." 1>&2
        return 1
    fi
    run_show "git branch -D $1 && git push origin --delete $1"
}

function sbmv() {
    if [ "$1" = "" ]; then
        echo " - Branch name required." 1>&2
        return 1
    fi
    local branch="${2:-`sh -c "$GIT_BRANCH"`}"
    run_show "git branch -m $branch $1 && git push origin :$branch $1"
}

function stag() {
    if [ "$1" = "" ]; then
        echo " - Tag required." 1>&2
        return 1
    fi
    run_show "git tag -a $1 -m \"$1\" && git push --tags && git fetch --tags"
}

function smtag() {
    if [ "$1" = "" ]; then
        echo " - Tag required." 1>&2
        return 1
    fi
    is_repository_clean; [ $? -gt 0 ] && return 1
    gcm;                 [ $? -gt 0 ] && return 1
    spll;                [ $? -gt 0 ] && return 1
    stag $1
}

function stag-() {
    if [ "$1" = "" ]; then
        echo " - Tag required." 1>&2
        return 1
    fi
    run_show "git tag -d \"$1\" && git push --delete origin \"$1\""
}

function sck() {
    if [ "$1" = "" ]; then
        echo " ! task name needed" 1>&2
        return 1
    fi
    local match=`echo "$1" | grep -Po '^([0-9])'`
    if [ "$match" = "" ]; then
        local branch="$1"
    else
        echo " - Branch name cannot be starting with digit." 1>&2
        return 1
    fi
    run_show "git checkout -b $branch 2> /dev/null || git checkout $branch"
}

function drop_this_branch_right_now() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    is_repository_clean; [ $? -gt 0 ] && return 1

    if [ "$branch" = "master" ]; then
        echo " ! Cannot delete MASTER branch" 1>&2
        return 1
    fi

    if [ "$branch" = "develop" ]; then
        echo " ! Cannot delete DEVELOP branch" 1>&2
        return 1
    fi

    run_show "git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D $branch"
    echo " => git push origin --delete $branch" 1>&2
}

function DROP_THIS_BRANCH_RIGHT_NOW() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1
    is_repository_clean; [ $? -gt 0 ] && return 1

    if [ "$branch" = "master" ]; then
        echo " ! Cannot delete MASTER branch" 1>&2
        return 1
    fi

    if [ "$branch" = "develop" ]; then
        echo " ! Cannot delete DEVELOP branch" 1>&2
        return 1
    fi

    local cmd="git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D $branch && git push origin --delete $branch"
    echo " -> $cmd" 1>&2
    eval ${cmd}
}

function is_repository_clean() {
    local modified='echo $(git ls-files --modified `git rev-parse --show-toplevel`)$(git ls-files --deleted --others --exclude-standard `git rev-parse --show-toplevel`)'
    if [ "`echo "$modified" | $SHELL`" != "" ]
    then
        local root="$(echo "$GIT_ROOT" | $SHELL)"
        echo " * isn't clean, found unstages changes: $root"
        return 1
    fi
}

function chdir_to_setupcfg {
    if [ ! -f 'setup.cfg' ]; then
        local root=`cat "$GIT_SEARCH_SETUPCFG" | $SHELL`
        if [ "$root" = "" ]; then
            echo " - setup.cfg not found in $cwd" 1>&2
            return 1
        fi
        cd $root
    fi
}

function gub() {
    cwd=`pwd`
    find . -maxdepth 3 -type d -name .git | while read git_directory
    do
        current_path=$(dirname "$git_directory")
        cd "${current_path}"
        local branch="`sh -c "$GIT_BRANCH"`"

        echo ""
        echo "    `pwd` <- $branch"
        run_silent "git fetch origin master && git fetch --tags --all"

        is_repository_clean
        if [ $? -gt 0 ]; then
            if [ "$branch" != "master" ]; then
                run_silent "git fetch origin $branch"
                echo "  - $branch modified, just fetch remote"
            fi
        else
            if [ "$branch" != "master" ]; then
                run_silent "git fetch origin $branch && git reset --hard origin/$branch && git pull origin $branch"
                echo "  + $branch fetch, reset and pull"
            else
                run_silent "git reset --hard origin/$branch && git pull origin $branch"
                echo "  + $branch reset and pull"
            fi
        fi
        cd "${cwd}"
    done
}

alias gmm='git commit -m'
alias gdd='git diff --name-only'
alias gdr='git ls-files --modified `git rev-parse --show-toplevel`'

# bindkey "^[^M" accept-and-hold # Esc-Enter

#              alt-q, commits history
bindkey "\eq"  git_widget_show_commits
#              shift-alt-q, branch -> history
bindkey "^[Q"  git_widget_select_branch_with_callback
#              ctrl-q, file -> history
bindkey "^q"   git_widget_select_file_show_commits
#              ctrl-alt-q, branch -> file -> history
bindkey "\e^q" git_widget_select_branch_then_file_show_commits

#              alt-a, git add
bindkey "\ea"  git_widget_add
#              shift-alt-a, checkout to active branch last commit
bindkey "^[A"  git_widget_checkout_modified
#              ctrl-a, on active branch, select commit, checkout files
bindkey "^a"   git_widget_select_commit_then_files_checkout
#              ctrl-alt-a, select branch, select commit, checkout files
bindkey "\e^a" git_widget_select_branch_then_commit_then_file_checkout

bindkey "^s"   git_widget_checkout_commit
bindkey "\es"  git_widget_checkout_branch
bindkey "^[S"  git_widget_merge_branch
bindkey "\e^s" git_widget_checkout_tag
bindkey "\ep"  git_widget_conflict_solver

#              alt-f, fetch remote branch and, if possible, checkout to + pull
bindkey "\ef"  git_widget_fetch_branch
#              shift-alt-f, delete local branch
bindkey "^[F"  git_widget_delete_branch
#              ctrl-alt-a, permanently delete REMOTE branch
bindkey "\e^f" git_widget_delete_remote_branch  # PUSH TO origin, caution!
