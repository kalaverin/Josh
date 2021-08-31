. $JOSH/lib/shared.sh

# ———

local THIS_DIR=`dirname "$($JOSH_READLINK -f "$0")"`
local INCLUDE_DIR="`realpath $THIS_DIR/git`"

local DIFF_FROM_TAG="$INCLUDE_DIR/git_diff_from_tag.sh"
local LIST_BRANCHES="$INCLUDE_DIR/git_list_branches.sh"
local SETUPCFG_LOOKUP="$INCLUDE_DIR/git_search_setupcfg.sh"
local TAG_FROM_STRING="$INCLUDE_DIR/git_tag_from_str.sh"

local ESCAPE_STATUS='sd "^( )" "." | sd "^(.)( )" "$1." | sd "^(. )" "++ "'
local GIT_DIFF="git diff --color=always --stat --patch --diff-algorithm=histogram"

# ———

alias git_list_commits="git log --color=always --format='%C(auto)%D %C(reset)%s %C(black)%C(bold)%ae %cr %<(12,trunc)%H' --first-parent"
alias -g pipe_remove_dots_and_spaces="sed -re 's/(\.{2,})+$//g' | sed -re 's/(\\s+)/ /g' | sd '^\s+' ''"
alias -g pipe_numerate="awk '{print NR,\$0}'"

DELTA_FOR_COMMITS_LIST_OUT="xargs -I$ git show --find-renames --find-copies --function-context --format='format:%H %ad%n%an <%ae>%n%s' --diff-algorithm=histogram $ | $DELTA --paging='always'"

# ———

function spll() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    run_show "git pull --ff-only --no-edit --no-commit --verbose origin $branch" 2>&1 | grep -v 'up to date'
    return $?
}

function sfet() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    if [ ! "$branch" = "`git_current_branch`" ]; then
        run_show "git fetch origin \"$branch\":\"$branch\"" 2>&1
    fi
    run_show "git fetch --verbose --all --tags" 2>&1 | grep -v 'up to date'
    return $?
}

function sall() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    is_repository_clean;                        [ $? -gt 0 ] && return 1
    sfet $branch;                               [ $? -gt 0 ] && return 1
    run_show "git reset --hard origin/$branch"; [ $? -gt 0 ] && return 1
    spll $branch
    return $?
}

function spsh() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    run_show "git push origin $branch"
    return $?
}

function sfm() {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    sfet $branch; [ $? -gt 0 ] && return 1
    run_show "git merge origin/$branch"
    return $?
}

function sbrm() {
    if [ "$1" = "" ]; then
        echo " - Branch name required." 1>&2
        return 1
    fi

    run_show "git branch -D $1 && git push origin --delete $1"
    return $?
}

function sbmv() {
    if [ "$1" = "" ]; then
        echo " - Branch name required." 1>&2
        return 1
    fi

    local branch="${2:-`$SHELL -c "$GET_BRANCH"`}"
    run_show "git branch -m $branch $1 && git push origin :$branch $1"
    return $?
}

function stag() {
    if [ "$1" = "" ]; then
        echo " - Tag required." 1>&2
        return 1
    fi

    run_show "git tag -a $1 -m \"$1\" && git push --tags && git fetch --tags"
    return $?
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
    return $?
}

function stag-() {
    if [ "$1" = "" ]; then
        echo " - Tag required." 1>&2
        return 1
    fi

    run_show "git tag -d \"$1\" && git push --delete origin \"$1\""
    return $?
}

function sck() {
    if [ "$1" = "" ]; then
        echo " - task name needed" 1>&2
        return 1
    fi
    local match=`echo "$1" | grep -Po '^([0-9])'`
    if [ "$match" = "" ]; then
        local branch="$1"
    else
        echo " - branch name can't starting with digit" 1>&2
        return 1
    fi
    run_show "git checkout -b $branch 2> /dev/null || git checkout $branch"
    return $?
}

function git_abort() {
    local state="`get_repository_state`"  # merging, rebase or cherry-pick
    [ "$?" -gt 0 ] && return 0
    [ "$state" ] && $SHELL -c "git $state --abort"
    zle reset-prompt
}
zle -N git_abort

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
    return $?
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

    run_show "git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D $branch && git push origin --delete $branch"
    return $?
}

function is_repository_clean() {
    local modified='echo $(git ls-files --modified `git rev-parse --show-toplevel`)$(git ls-files --deleted --others --exclude-standard `git rev-parse --show-toplevel`)'
    if [ "`echo "$modified" | $SHELL`" != "" ]; then
        local root="$(echo "$GET_ROOT" | $SHELL)"
        echo " * isn't clean, found unstages changes: $root"
        return 1
    fi
    return 0
}

function chdir_to_setupcfg {
    if [ ! -f 'setup.cfg' ]; then
        local root=`cat "$SETUPCFG_LOOKUP" | $SHELL`
        if [ "$root" = "" ]; then
            echo " - setup.cfg not found in $cwd" 1>&2
            return 1
        fi
        cd $root
    fi
    return 0
}

function gub() {
    cwd=`pwd`
    find . -maxdepth 3 -type d -name .git | while read git_directory
    do
        current_path=$(dirname "$git_directory")
        cd "${current_path}"
        local branch="`$SHELL -c "$GET_BRANCH"`"

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


# ———

local GET_ROOT='git rev-parse --quiet --show-toplevel'
git_root() {
    local result="`$SHELL -c "$GET_ROOT" 2>/dev/null`"
    if [ "$result" ]; then
        local result=$(realpath --quiet `$SHELL -c "$GET_ROOT" 2>/dev/null`)
        [ "$result" ] && echo "$result"
    fi
}

local GET_HASH='git rev-parse --quiet --verify HEAD 2>/dev/null'
git_current_hash() {
    local result="`$SHELL -c "$GET_HASH"`"
    [ "$result" ] && echo "$result"
}

local GET_BRANCH='git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null'
git_current_branch() {
    local result="`$SHELL -c "$GET_BRANCH"`"
    if [ "$result" = "HEAD" ]; then
        if [ ! "`git name-rev --name-only HEAD 2>&1 | grep -Pv '^(Could not get sha1)'`" ]; then
            echo " - empty repository `git_root` without any commits?" >&2
            local result="`git symbolic-ref --short HEAD`"
        fi
    fi
    [ "$result" ] && echo "$result"
}

get_repository_state() {
    local root="`git_root`"
    # local root="`git_root 2>/dev/null`"
    [ ! "$root" ] && return 1

    if [ -f "$root/.git/CHERRY_PICK_HEAD" ]; then
        local state="cherry-pick"
    elif [ -f "$root/.git/REBASE_HEAD" ]; then
        local state="rebase"
    elif [ -f "$root/.git/MERGE_HEAD" ]; then
        local state="merge"
    fi

    [ ! "$state" ] && return 1
    echo "$state"
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
    local select='git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file'
    # local select='git ls-files --deleted --others --exclude-standard'

    while true; do
        local value="$(
            $SHELL -c "$select | $ESCAPE_STATUS \
            | $FZF \
            --filepath-word --tac \
            --multi --nth=2.. --with-nth=1.. \
            --preview=\"$GIT_DIFF $branch -- {2} | $DELTA\" \
            --preview-window=\"left:`get_preview_width`:noborder\" \
            --prompt='git add >  ' \
            | tabulate -i 2 | sort --human-numeric-sort | $UNIQUE_SORT \
            | $LINES_TO_LINE")"
            # | xargs -n 1 realpath --quiet --relative-to=$cwd 2>/dev/null \

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

        if [ "`get_repository_state`" ]; then  # merging, rebase or cherry-pick
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
    # TODO: untracked must be removed
    local select='git status --short --verbose --no-ahead-behind --untracked-files=no'

    while true; do
        local value="$(
            $SHELL -c "$select | $ESCAPE_STATUS \
            | $FZF \
            --filepath-word --tac \
            --multi --nth=2.. --with-nth=1.. \
            --preview=\"$GIT_DIFF -R $branch -- {2} | $DELTA\" \
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


open_editor_on_conflict() {
    local line="$($SHELL -c "
        grep -P --line-number --max-count=1 '^>>>>>>>' $1 | tabulate -d ':' -i 1
    ")"
    if [ "$line" -gt 0 ]; then
        $EDITOR $* +$line
        return $?
    fi
}


git_auto_skip_or_continue() {
    local state="`get_repository_state`"  # merging, rebase or cherry-pick
    if [ "$state" ]; then
        # nothing to resolve, just skip
        local files="`git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file | wc -l`"
        if [ "$files" -eq 0 ]; then
            if [ "$state" != "merge" ]; then
                run_show " git $state --skip"
            else
                run_show " git merge --continue"
            fi
            return 1
        fi

        # all files resolved and no more changes, then — continue
        local files="`git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file | grep -Pv '^([AM] )' | wc -l`"
        if [ "$files" -eq 0 ]; then
            run_show " git $state --continue"
            return 2
        fi
        return 3
    fi
    return 0
}


git_widget_conflict_solver() {
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    git_auto_skip_or_continue
    local state="$?"
    [ "$state" -eq 0 ] && return 2

    local cwd="`pwd`"
    local select='git status \
        --short --verbose --no-ahead-behind \
        | grep -P "^(AA|UU)" | tabulate -i 2'

    local conflicted='xargs rg \
        --files-with-matches --with-filename --color always \
        --count --heading --line-number "^(<<<<<<< HEAD)\s*$" | tabulate -d ":"'

    local need_quit=0
    local last_hash=""

    while true; do
        while true; do
            local value="$(
                $SHELL -c "$select | $conflicted | $UNIQUE_SORT \
                | $FZF \
                --exit-0 \
                --select-1 \
                --filepath-word --tac \
                --multi --nth=1.. --with-nth=1.. \
                --prompt=\"$branch solving >  \" \
                --preview=\"$GIT_DIFF $branch -- {1} | $DELTA\" \
                --preview-window=\"left:`get_preview_width`:noborder\" \
                | sd '(\s*\d+)$' '' | $UNIQUE_SORT | $LINES_TO_LINE")"

            if [ ! "$value" ]; then
                # if exit without selection
                local need_quit=1
                break
            fi

            local file_hash="`md5sum $value | tabulate -i 1`"
            if [ "$last_hash" = "$file_hash" ]; then
                # prevent infinite loop with select-1
                local need_quit=1
                break
            fi

            open_editor_on_conflict $value
            local last_hash="$file_hash"

            local conflits_count=$($SHELL -c "echo \"$value\" | $conflicted | wc -l")
            if [ ! "$conflits_count" -gt 0 ]; then
                run_show " git add $value"
            fi

            local files="$($SHELL -c "$select | $conflicted | $UNIQUE_SORT")"
            if [ ! "$files" ]; then
                # if last file committed, but not manually exit from select menu
                break
            fi
        done

        [ "$need_quit" -gt 0 ] && break

        git_auto_skip_or_continue
        [ ! $? -gt 0 ] && break
    done

    zle reset-prompt
    if [ "$state" -eq 3 ]; then
        echo "+ repository in state \``get_repository_state`\`, but no conflicts found, check git-add widget\n"
    fi
    zle redisplay
    return 0
}
zle -N git_widget_conflict_solver


git_widget_select_commit_then_files_checkout() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GET_BRANCH" | $SHELL)}
        local commit="$(git_list_commits "$branch" \
            | pipe_remove_dots_and_spaces \
            | sed 1d \
            | pipe_numerate \
            | fzf \
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

        local root=$(realpath `$SHELL -c "$GET_ROOT"`)
        local differ="echo {} | xargs -I% git diff --color=always --shortstat --patch --diff-algorithm=histogram $branch $commit -- $root/% | $DELTA"
        while true; do
            local files="$(git diff --name-only $branch $commit | sort | \
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
                    --multi --tac \
                    --prompt="$branch: select file >  " \
                    --filepath-word --preview="$differ" \
                | proximity-sort . | sed -z 's:\n: :g' | awk '{$1=$1};1' \
                | sed -r "s:\s\b: $root/:g" | xargs -I% echo "$root/%"
            )"

            if [[ "$files" != "" ]]; then
                # TODO: filter files for exists
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


git_widget_show_commits() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GET_BRANCH" | $SHELL)}
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
    local branch="`git_current_branch`"
    [ ! "$branch" ] && return 1

    while true; do
        local branch="$($SHELL $LIST_BRANCHES | sed 1d | \
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
                --preview="$GIT_DIFF $branch {1} | $DELTA " \
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
        local branch=${1:-$(echo "$GET_BRANCH" | $SHELL)}

        local differ="$LISTER_FILE --terminal-width=\$FZF_PREVIEW_COLUMNS {}"
        local diff_file="'git show --diff-algorithm=histogram --format=\"%C(yellow)%h %ad %an <%ae>%n%s%C(black)%C(bold) %cr\" \$0 --"

        while true; do
            local file="$(git ls-files | sort | \
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
                    --color="$FZF_THEME" --tac \
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
        local current="$(echo "$GET_BRANCH" | $SHELL)"

        local cmd="echo {} | $SHELL $DIFF_FROM_TAG | $DELTA --paging='always'"

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
                --preview=$cmd | $SHELL $TAG_FROM_STRING \
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
    local select='git for-each-ref \
                    --sort=-committerdate refs/heads/ \
                    --color=always \
                    --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" \
                    | awk "{\$1=\$1};1" | grep -Pv "^(\*\s+)"'
    while true; do
        local value="$(
            $SHELL -c "$select \
            | $FZF \
            --preview=\"$GIT_DIFF $branch {1} | $DELTA \" \
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

    local differ="echo {} | tabulate -i 1 | xargs -n 1 $GIT_DIFF"
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
        --multi \
        --prompt='DELETE REMOTE BRANCH >  ' \
        --preview=\"$differ\" \
        --preview-window=\"left:`get_preview_width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")"

    [ "$value" = "" ] && return 0

    local value=$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')
    local cmd="git branch -D $value; git push origin --delete $value"

    if [[ "$BUFFER" != "" ]]; then
        LBUFFER="$BUFFER && $cmd"
    else
        LBUFFER=" $cmd"
    fi
    zle reset-prompt
    return 0
}
zle -N git_widget_delete_remote_branch


git_widget_checkout_commit() {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch="$(echo "$GET_BRANCH" | $SHELL)"
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
                --prompt="checkout >  " \
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
    local differ="echo {} | tabulate -i 1 | xargs -n 1 $GIT_DIFF"
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
            --prompt=\"merge to $branch $state>  \" \
            | cut -d ' ' -f 1
        ")"
        if [ ! "$value" ]; then
            break

        elif [ ! "$BUFFER" ]; then
            run_show "sfet \"$value\" && git merge --no-commit \"origin/$value\""
            local retval=$?
            git_widget_conflict_solver

        elif [ "$value" ]; then
            LBUFFER="$BUFFER && git fetch origin \"$value\":\"$value\" && git merge --no-commit \"origin/$value\""
        fi

        break
    done
    zle reset-prompt
    return 0
}
zle -N git_widget_merge_branch

# ———

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

#              alt-s, go to branch
bindkey "\es"  git_widget_checkout_branch
#              shift-alt-a, fetch another and merge branch
bindkey "^[S"  git_widget_merge_branch
#              ctrl-s, go to commit
bindkey "^s"   git_widget_checkout_commit
#              ctrl-alt-a, go to tag
bindkey "\e^s" git_widget_checkout_tag

#              alt-f, fetch remote branch and, if possible, checkout to + pull
bindkey "\ef"  git_widget_fetch_branch
#              shift-alt-f, delete local branch
bindkey "^[F"  git_widget_delete_branch
#              ctrl-alt-a, permanently delete REMOTE branch
bindkey "\e^f" git_widget_delete_remote_branch  # PUSH TO origin, caution!

#              alt-p, experimental conflict solver
bindkey "\ep"  git_widget_conflict_solver
#              ctrl-p, git abort
bindkey "^p"   git_abort
