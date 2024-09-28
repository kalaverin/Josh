function __widget.git.add {
    local branch
    local cwd="$PWD"
    branch="$(git.this.branch)" || return "$?"

    while true; do
        local value="$(
            $SHELL -c "$LIST_TO_ADD | $ESCAPE_STATUS \
            | $FZF \
            --filepath-word --tac \
            --multi --nth=2.. --with-nth=1.. \
            --preview=\"$GIT_DIFF -- {2} | $DELTA\" \
            --preview-window=\"left:`misc.preview.width`:noborder\" \
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

        if [[ "$branch" =~ "^[0-9A-Za-z-]+$" ]]; then
            local prefix="$branch: "
        else
            local prefix=""
        fi

        if [ "`git.this.state`" ]; then  # merging, rebase or cherry-pick
            LBUFFER="$command $value "
            RBUFFER=''
        else
            LBUFFER="$command $value && git commit -m \"$prefix"
            RBUFFER='"'
        fi
        zle redisplay
        local retval="$?"
        break
    done
    return "$retval"
}
zle -N __widget.git.add

function __widget.git.checkout_modified {
    local branch="`git.this.branch`"
    [ ! "$branch" ] && return 1

    local cwd="`pwd`"
    # TODO: untracked must be removed
    # TODO: deleted must be restored
    local select='git status --short --verbose --no-ahead-behind --untracked-files=no'

    while true; do
        local value="$(
            $SHELL -c "$select | $ESCAPE_STATUS \
            | $FZF \
            --filepath-word --tac \
            --multi --nth=2.. --with-nth=1.. \
            --preview=\"$GIT_DIFF -R $branch -- {2} | $DELTA\" \
            --preview-window=\"left:`misc.preview.width`:noborder\" \
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
zle -N __widget.git.checkout_modified

function __widget.git.auto_skip_or_continue {
    local state="`git.this.state`"  # merging, rebase or cherry-pick
    if [ "$state" ]; then
        # nothing to resolve, just skip
        local files=$($SHELL -c "$LIST_TO_ADD | wc -l")
        if [ "$files" -eq 0 ]; then
            if [ "$state" != "merge" ]; then
                run.show " git $state --skip"
            else
                run.show " git merge --continue"
            fi
            return 1
        fi

        # all files resolved and no more changes, then — continue
        local files=$($SHELL -c "$LIST_TO_ADD | grep -Pv '^([AMD] )' | wc -l")
        if [ "$files" -eq 0 ]; then
            run.show " git $state --continue"
            return 2
        fi
        return 3
    fi
    return 0
}

function __widget.git.conflict_solver {
    local branch="`git.this.branch`"
    [ ! "$branch" ] && return 1

    __widget.git.auto_skip_or_continue
    local state="$?"
    [ "$state" -eq 0 ] && return 2

    local cwd="`pwd`"
    local select='git status \
        --short --verbose --no-ahead-behind \
        | grep -P "^(AA|UU)" | tabulate -i 2'

    local conflicted='xargs rg \
        --files-with-matches --with-filename --color always \
        --count --heading --line-number "^(<<<<<<< )" | tabulate -d ":"'

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
                --preview-window=\"left:`misc.preview.width`:noborder\" \
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
                run.show " git add $value"
            fi

            local files="$($SHELL -c "$select | $conflicted | $UNIQUE_SORT")"
            if [ ! "$files" ]; then
                # if last file committed, but not manually exit from select menu
                break
            fi
        done

        [ "$need_quit" -gt 0 ] && break

        __widget.git.auto_skip_or_continue
        [ ! $? -gt 0 ] && break
    done

    zle reset-prompt
    if [ "$state" -eq 3 ]; then
        local state="`git.this.state`"
        local conflicts_amount="$($SHELL -c "$select | $UNIQUE_SORT | wc -l")"
        if [ "$conflicts_amount" -gt 0 ]; then
            local conflicts_amount=" and $conflicts_amount files with conflicts block auto$state"
        else
            local conflicts_amount=", but no conflicts found (check git-add widget?)"
        fi
    fi
    zle redisplay
    return 0
}
zle -N __widget.git.conflict_solver

function __widget.git.select_commit_then_files_checkout {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GET_BRANCH" | $SHELL)}
        local commit="$(git_list_commits "$branch" \
            | GLOB_PIPE_REMOVE_DOTS \
            | GLOB_PIPE_REMOVE_SPACES \
            | sed 1d \
            | GLOB_PIPE_NUMERATE \
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
                --preview-window="left:`misc.preview.width`:noborder" \
                --prompt="$branch: select commit >  " \
                --preview="echo {} | $CMD_EXTRACT_TOP_COMMIT | xargs -I% git diff --color=always --shortstat --patch --diff-algorithm=histogram $branch % | $DELTA --paging='always'" | $CMD_EXTRACT_TOP_COMMIT
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
                    --preview-window="left:`misc.preview.width`:noborder" \
                    --multi --tac \
                    --prompt="$branch: select file >  " \
                    --filepath-word --preview="$differ" \
                | proximity-sort . | sed -z 's:\n: :g' | awk '{$1=$1};1' \
                | sed -r "s:\s\b: $root/:g" | xargs -I% echo "$root/%"
            )"

            if [[ "$files" != "" ]]; then
                # TODO: filter files for exists
                run.show "git checkout $commit -- $files && git reset $files > /dev/null && git diff HEAD --stat --diff-algorithm=histogram --color=always | xargs -I$ echo $"
                zle reset-prompt
                return 130
            else
                return 0
            fi
        done
    fi
}
zle -N __widget.git.select_commit_then_files_checkout


function __widget.git.select_branch_then_commit_then_file_checkout {
    __widget.git.select_branch_with_callback __widget.git.select_commit_then_files_checkout
}
zle -N __widget.git.select_branch_then_commit_then_file_checkout


function __widget.git.show_commits {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch=${1:-$(echo "$GET_BRANCH" | $SHELL)}

        eval "git_list_commits $branch" | GLOB_PIPE_NUMERATE | \
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
                --preview-window="left:`misc.preview.width`:noborder" \
                --prompt="$branch >  " \
                --bind="enter:execute(echo {} | $CMD_EXTRACT_TOP_COMMIT | $CMD_XARGS_SHOW_TO_COMMIT)" \
                --preview="echo {} | $CMD_EXTRACT_TOP_COMMIT | $CMD_XARGS_SHOW_TO_COMMIT"

        local ret=$?
        if [[ "$ret" == "130" ]]; then
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        fi
    fi
}
zle -N __widget.git.show_commits


function __widget.git.select_branch_with_callback {
    local branch="`git.this.branch`"
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
                --preview-window="left:`misc.preview.width`:noborder" \
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

        ${1:-__widget.git.show_commits} $branch
        local ret=$?
        if [[ "$ret" == "130" ]]; then
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        fi
    done
}
zle -N __widget.git.select_branch_with_callback


function __widget.git.show_branch_file_commits {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local file="$2"
        local branch="$1"

        local ext="$(echo "$file" | xargs -I% basename % | grep --color=never -Po '(?<=.\.)([^\.]+)$')"

        local diff_view="echo {} | $CMD_EXTRACT_TOP_COMMIT | xargs -l $SHELL -c $diff_file $file' | $DELTA"

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
                --preview-window="left:`misc.preview.width`:noborder" \
                --prompt="$branch:$file >  " \
                --preview="$diff_view" \
                --bind="enter:execute($file_view)"
    fi
}
zle -N __widget.git.show_branch_file_commits


function __widget.git.select_file_show_commits {
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
                    --preview-window="left:`misc.preview.width`:noborder" \
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

            __widget.git.show_branch_file_commits $branch $file
            local ret=$?
            if [[ "$ret" != "130" ]]; then
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            fi
        done
    fi
}
zle -N __widget.git.select_file_show_commits


function __widget.git.select_branch_then_file_show_commits {
    __widget.git.select_branch_with_callback __widget.git.select_file_show_commits
}
zle -N __widget.git.select_branch_then_file_show_commits


function __widget.git.checkout_tag {
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
                --preview-window="left:`misc.preview.width`:noborder" \
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
zle -N __widget.git.checkout_tag


function __widget.git.switch_branch {
    # нужен нормальный просмотровщик диффа между хешами
    # git rev-list --first-parent develop...master --pretty=oneline | sd "(.{8})(.{32}) (.+)" "\$1 \$3" | GLOB_PIPE_NUMERATE | sort -hr
    local branch verb
    branch="$(git.this.branch)" || return "$?"
    [ -z "$branch" ] && return 1

    verb="$(git.cmd.checkout.verb)"

    git.is_clean 2>/dev/null || local state='DIRTY '

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
            --preview-window=\"left:`misc.preview.width`:noborder\" \
            --prompt=\"branch $state>  \" \
            | cut -d ' ' -f 1
        ")"

        if [ -z "$value" ]; then
            break
        else
            local cmd="git $verb $value 2>/dev/null 1>/dev/null && git.mtime.set"

            if [ -n "$BUFFER" ]; then
                LBUFFER="$BUFFER && $cmd"
                local retval=0
            else
                run.show "$cmd"
                local retval="$?"
            fi
        fi
        break
    done
    zle reset-prompt
    return "$retval"
}
zle -N __widget.git.switch_branch


function __widget.git.fetch_branch {
    local already_checked_out_branches branch cmd count filter root value

    root="$(git.this.root)" || return "$?"
    [ -z "$root" ] && return 1

    branch="$(git.this.branch)" || return "$?"

    local select='git ls-remote --heads --quiet origin | \
                  sd "^([0-9a-f]+)\srefs/heads/(.+)" "\$1 \$2"'

    filter="sort -Vk 2 | awk '{a[i++]=\$0} END {for (j=i-1; j>=0;) print a[j--] }'"
    already_checked_out_branches="$(eval.run " \
        git show-ref --heads \
        | sd '^([0-9a-f]+)\srefs/heads/(.+)' '\$2' \
        | tabulate -i 1 | $LINES_TO_LINE | sd ' ' '|'
    ")" || return "$?"
    if [ -n "$already_checked_out_branches" ]; then
        filter="grep -Pv '($already_checked_out_branches)$'| $filter"
    fi

    local differ="echo {} | tabulate -i 1 | xargs -i$ echo 'git diff $ 1&>/dev/null 2&>/dev/null || git fetch origin --depth=1 $ && git diff --color=always --shortstat --patch --diff-algorithm=histogram -- $ $branch' | $SHELL | $DELTA"

    value="$(
        $SHELL -c "$select | $filter \
        | $FZF \
        --prompt='fetch branch >  ' \
        --multi \
        --preview=\"$differ\" \
        --preview-window=\"left:`misc.preview.width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")" || return "$?"
    [ -z "$value" ] && return 0

    local count="$(echo "$value" | wc -l)" || return "$?"
    local value="$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')" || return "$?"

    if [ "$count" -gt 1 ]; then
        cmd="git.is_clean"
        for b in `echo "$value" | sd '(\s+)' '\n'`; do
            cmd="$cmd && git fetch origin '$b':'$b'"
        done

        for b in `echo "$value" | sd '(\s+)' '\n'`; do
            cmd="$cmd && git checkout --force --quiet '$b' && git reset --hard '$b' && git pull origin '$b'"
        done

        run.show "$cmd && git.mtime.set"
    else
        git.branch.select $value
    fi
    zle reset-prompt
    return $?
}
zle -N __widget.git.fetch_branch


function __widget.git.delete_branch {
    local root="`git.this.root`"
    [ ! "$root" ] && return 1
    local branch="`git.this.branch`"

    local select='git ls-remote --heads --quiet origin | \
                  sd "^([0-9a-f]+)\srefs/heads/(.+)" "\$1 \$2"'

    local filter="sort -Vk 2 | awk '{a[i++]=\$0} END {for (j=i-1; j>=0;) print a[j--] }'"

    local differ="echo {} | tabulate -i 1 | xargs -i$ echo 'git diff $ 1&>/dev/null 2&>/dev/null || git fetch origin --depth=1 $ && git diff --color=always --shortstat --patch --diff-algorithm=histogram $ $branch' | $SHELL | $DELTA"

    local value="$(
        $SHELL -c "$select | $filter \
        | $FZF \
        --multi \
        --prompt='DELETE REMOTE & LOCAL BRANCH >  ' \
        --preview=\"$differ\" \
        --preview-window=\"left:`misc.preview.width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")"

    [ "$value" = "" ] && return 0

    local value=$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')
    local cmd="git branch -D $value; git push origin --delete $value; git remote prune origin"

    if [[ "$BUFFER" != "" ]]; then
        LBUFFER="$BUFFER && $cmd"
    else
        LBUFFER=" $cmd"
    fi
    zle reset-prompt
    return 0
}
zle -N __widget.git.delete_branch


function __widget.git.delete_local_branch {
    local branch="`git.this.branch`"
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
            --preview-window=\"left:`misc.preview.width`:noborder\" \
            --prompt=\"DELETE LOCAL BRANCH >  \" \
            | cut -d ' ' -f 1 | $UNIQUE_SORT | $LINES_TO_LINE
        ")"

        if [ "$value" ]; then
            local cmd="git branch -D $value; git remote prune origin"
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
zle -N __widget.git.delete_local_branch


function __widget.git.delete_remote_branch {
    local root="`git.this.root`"
    [ ! "$root" ] && return 1
    local branch="`git.this.branch`"

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
        --preview-window=\"left:`misc.preview.width`:noborder\" \
        | cut -d ' ' -f 2 \
    ")"

    [ "$value" = "" ] && return 0

    local value=$(echo "$value" | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n: :g')
    local cmd="git push origin --delete $value"

    if [[ "$BUFFER" != "" ]]; then
        LBUFFER="$BUFFER && $cmd"
    else
        LBUFFER=" $cmd"
    fi
    zle reset-prompt
    return 0
}
zle -N __widget.git.delete_remote_branch


function __widget.git.checkout_commit {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch="$(echo "$GET_BRANCH" | $SHELL)"
        local result="$(eval "git_list_commits $branch" | GLOB_PIPE_NUMERATE | \
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
                --preview-window="left:`misc.preview.width`:noborder" \
                --color="$FZF_THEME" \
                --prompt="checkout >  " \
                --preview="echo {} | $CMD_EXTRACT_TOP_COMMIT | $CMD_XARGS_DIFF_TO_COMMIT"
        )"

        if [[ "$result" != "" ]]; then
            local commit="$(echo "$result" | $CMD_EXTRACT_TOP_COMMIT)"

            if [[ "$commit" == "" ]]; then
                zle reset-prompt
                return 1
            fi

            if [[ "$BUFFER" != "" ]]; then
                LBUFFER="$BUFFER && git checkout $commit && git.mtime.set"
                local ret=$?
                zle redisplay
                typeset -f zle-line-init >/dev/null && zle zle-line-init
                return $ret
            fi

            run.show "git checkout $commit 2>/dev/null && git.mtime.set"
        fi
        zle reset-prompt
        return 0
    fi
}
zle -N __widget.git.checkout_commit


function __widget.git.merge_branch {
    local branch="`git.this.branch`"
    [ ! "$branch" ] && return 1

    git.is_clean >/dev/null || local state='(dirty!) '
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
            --preview-window=\"left:`misc.preview.width`:noborder\" \
            --prompt=\"merge to $branch $state>  \" \
            | cut -d ' ' -f 1
        ")"
        if [ ! "$value" ]; then
            break

        elif [ ! "$BUFFER" ]; then
            run.show "git.fetch \"$value\" && git merge --no-commit \"origin/$value\""
            local retval=$?
            __widget.git.conflict_solver

        elif [ "$value" ]; then
            LBUFFER="$BUFFER && git fetch origin \"$value\":\"$value\" && git merge --no-commit \"origin/$value\""
        fi

        break
    done
    zle reset-prompt
    return 0
}
zle -N __widget.git.merge_branch


function __widget.git.rebase_branch {
    local branch="`git.this.branch`"
    [ ! "$branch" ] && return 1

    git.is_clean >/dev/null || local state='(dirty!) '
    local differ="echo {} | tabulate -i 1 | xargs -n 1 $GIT_DIFF"
    local select='git for-each-ref \
                    --sort=-committerdate refs/heads/ \
                    --color=always \
                    --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" \
                    '

    local value="$(
        $SHELL -c "$select \
        | $FZF \
        --preview=\"$differ $branch | $DELTA \" \
        --preview-window=\"left:`misc.preview.width`:noborder\" \
        --prompt=\"rebase $branch $state>  \" | head -n 1
    ")"
    local value="$(echo "$value" | sed -z 's:^*::g' | sed -z 's:^ ::g' | tabulate -i 1)"

    if [ ! "$value" ]; then
        return 0
    elif [[ "$value" == '*' ]]; then
        local value="$branch"
    fi

    local command="`git.cmd.fetch "$value"` && git rebase --stat --interactive --no-autosquash --autostash \"origin/$value\""

    if [ ! "$BUFFER" ]; then
        LBUFFER=" $command"
    else
        LBUFFER="$BUFFER && $command"
    fi

    zle reset-prompt
    return 0
}
zle -N __widget.git.rebase_branch


function __widget.git.replace_all_commits_with_one {
    local branch="${1:-`git.this.branch`}"
    [ ! "$branch" ] && return 1

    local parent="$(git show-branch | grep '*' | grep -v "`git rev-parse --abbrev-ref HEAD`" | head -n 1 | sd '^(.+)\[' '' | tabulate -d '] ' -i 1)"
    [ ! "$parent" ] && return 2

    git.fetch "$parent"

    local count="$(git rev-list --first-parent --count "^$parent" "$branch")"
    [ "$count" -eq 0 ] && return 3

    local command=" git reset --soft HEAD~$count && git add ."
    [ "$BUFFER" ] && local command="$BUFFER && $command"

    if [ "`git.this.state`" ]; then  # merging, rebase or cherry-pick
        LBUFFER="$command"
        RBUFFER=''
    else
        LBUFFER="$command && git commit -m \"$branch: "
        RBUFFER='"'
    fi
    zle reset-prompt
    return 0
}
zle -N  __widget.git.replace_all_commits_with_one


function __widget.git.squash_to_commit {
    if [ "`git rev-parse --quiet --show-toplevel 2>/dev/null`" ]; then
        local branch="$(echo "$GET_BRANCH" | $SHELL)"
        local result="$(eval "git_list_commits $branch" | GLOB_PIPE_NUMERATE | \
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
                --preview-window="left:`misc.preview.width`:noborder" \
                --color="$FZF_THEME" \
                --prompt="rebased squash to >  " \
                --preview="echo {} | $CMD_EXTRACT_TOP_COMMIT | $CMD_XARGS_DIFF_TO_COMMIT"
        )"

        if [[ "$result" != "" ]]; then
            local commit="$(echo "$result" | eval "$CMD_EXTRACT_TOP_COMMIT")"

            echo ">$commit"
            if [[ "$commit" == "" ]]; then
                zle reset-prompt
                return 1
            fi

            local command="git rebase --interactive --no-autosquash --no-autostash --strategy=recursive --strategy-option=ours --strategy-option=diff-algorithm=histogram \"$commit\""
            if [[ "$BUFFER" != "" ]]; then
                command="$BUFFER && $command"
            fi

            LBUFFER="$command"
            RBUFFER=''

            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
        fi
        zle reset-prompt
        return 0
    fi
}
zle -N  __widget.git.squash_to_commit
