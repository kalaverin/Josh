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
                | fzf \
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


function __widget.git.select_files_from_commit {
    local branch commit result root

    root="$(git.root 2>/dev/null)" || return 0
    branch="$(git.this.branch)" || return "$?"

    while true; do
        result="$(git_list_commits "$branch" \
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
                --preview-window="left:`misc.preview.width`:noborder" \
                --color="$FZF_THEME" \
                --prompt="commit -> file >  " \
                --preview="echo {} | $CMD_EXTRACT_COMMIT | $CMD_XARGS_SHOW_TO_COMMIT"
        )"
        if [[ -z "$result" ]]; then
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return 0
        fi
        commit="$(run.out "echo '$result' | $CMD_EXTRACT_COMMIT")" || return "$?"

        local files
        local differ="echo {} | sed 's: +$::' | xargs -I$ $SHELL $DIFF_SHOW_PLEASE $commit $root $ | $CMD_DELTA"

        while true; do
            files="$(
                git show --stat --stat-width=2048 "$commit" | \
                grep '|' | sed 's:|.\+::' | sed 's/[[:space:]]*$//g' | sort -V | \
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
                    --prompt="$branch: file >  " \
                    --preview="$differ" \
                    --filepath-word \
            )"

            if [ "$?" -eq 130 ] || [ -z "$files" ]; then
                break
            fi

                # TODO: filter files for exists
                run.show "git checkout $commit -- $files && git reset $files > /dev/null && git diff HEAD --stat --diff-algorithm=histogram --color=always | xargs -I$ echo $"
                zle reset-prompt
                return 130
        done
    done
}
zle -N __widget.git.select_files_from_commit


function __widget.git.select_branch_then_commit_then_file_checkout {
    __widget.git.select_branch_with_callback __widget.git.select_files_from_commit
}
zle -N __widget.git.select_branch_then_commit_then_file_checkout


function __widget.git.select_branch_with_callback {
    local branch
    branch="$(git.this.branch)" || return "$?"

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
    root="$(git.this.root 2>/dev/null)" || return "$?"
    if [ -x "$root" ]; then

        local branch="$1"
        local file="$2"

        local ext="$(echo "$file" | xargs -I% basename % | grep --color=never -Po '(?<=.\.)([^\.]+)$')"
        local diff_view="echo {} | $CMD_EXTRACT_TOP_COMMIT | xargs -l $SHELL -c $diff_file $file' | $DELTA"

        local file_view="echo {} | cut -d ' ' -f 1 | xargs -I^^ git show ^^:./$file | $LISTER_FILE --paging=always"
        if [ -n "$ext" ]; then
            local file_view="$file_view --language $ext"
        fi

        eval "git log --color=always --format='%C(reset)%C(blue)%C(dim)%h%C(auto)%d %C(reset)%s %C(brightblack)%C(dim)%an %C(black)%>(512)%>(32,trunc)%H%C(reset)%C(brightblack)%C(dim)' --first-parent $branch -- $file" | sed -r 's%^(\*\s+)%%g' | \
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
    local branch root
    local differ="$LISTER_FILE --terminal-width=\$FZF_PREVIEW_COLUMNS {}"
    local diff_file="'git show --diff-algorithm=histogram --format=\"%C(yellow)%h %ad %an <%ae>%n%s%C(black)%C(bold) %cr\" \$0 --"

    root="$(git.this.root 2>/dev/null)" || return "$?"
    if [ -x "$root" ]; then
        branch="$(git.this.branch)" || return "$?"

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

            __widget.git.show_branch_file_commits "$branch" "$file"
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
        | fzf \
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
        | fzf \
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
            | fzf \
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
        | fzf \
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


function __widget.git.replace_all_commits_with_one {
    local branch="${1:-`git.this.branch`}"
    [ ! "$branch" ] && return 1

    local parent="$(
        git show-branch | grep '*' | \
        grep -v "$branch" | \
        head -n 1 | sd '^(.+)\[' '' | tabulate -d '] ' -i 1)"

    [ ! "$parent" ] && return 2

    git.fetch "$parent"

    local count="$(git rev-list --first-parent --count "^$parent" "$branch")"
    [ "$count" -eq 0 ] && return 3

    local command=" git reset --soft HEAD~$count && git add ."
    [ "$BUFFER" ] && local command="$BUFFER && $command"

    if [ -n "$(git.this.state)" ]; then  # merging, rebase or cherry-pick
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
            eval "$FZF --prompt=\"rebased squash to > \" --preview-window=\"left:`misc.preview.width`:noborder\" --preview=\"echo {} | $CMD_EXTRACT_TOP_COMMIT | $CMD_XARGS_DIFF_TO_COMMIT\""
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


# renewed


function __widget.git.switch_branch {
    local branch command result state

    git.this.root 1>/dev/null 2>/dev/null || return true
    git.is_clean >/dev/null || state='(dirty) '

    branch="$(git.this.branch)" || return "$?"

    local result="$(
        git for-each-ref --sort=-committerdate refs/heads/ --color=always --format="%(HEAD)%(color:reset)%(color:green dim)%(objectname:short) %(color:reset)%(color:brightyellow)%(refname:short) %(color:reset)%(contents:subject) %(color:brightblack dim)%(authorname) %(color:black)%>(512)%>(32,trunc)%(objectname)%(color:reset)%(color:brightblack dim)" | \
        grep -Pv "^(\*)" | \
        eval "$FZF --preview=\"$GIT_DIFF $branch {1} | $DELTA \" --preview-window=\"left:`misc.preview.width`:noborder\" --prompt=\"switch $branch $state> \"" | awk "{\$1=\$1};1"
    )" || return "$?"

    if [ -n "$result" ]; then

        verb="$(git.cmd.checkout.verb)" || return "$?"
        result="$(run.out "echo '$result' | tabulate -i 2")" || return "$?"

        local command="git $verb $result 2>/dev/null 1>/dev/null && git.mtime.set"
        if [ -n "$BUFFER" ]; then
            LBUFFER="$BUFFER && $command"
            local retval="0"
        else
            run.show "$command"
            local retval="$?"
        fi
    fi

    zle reset-prompt
    zle redisplay
    return "$retval"
}
zle -N __widget.git.switch_branch


function __widget.git.add {
    local branch command commit result prefix state

    git.this.root 1>/dev/null 2>/dev/null || return true
    branch="$(git.this.branch)" || return "$?"

    local differ="$SHELL $DIFF_SHOW_OR_CONTENT '$branch' {2} | $CMD_DELTA"
    result="$(
        git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-files | \
        sort --human-numeric-sort | eval $ESCAPE_STATUS | \
        eval $FZF \
            --filepath-word --tac --multi --with-nth=1.. --nth=2.. \
            --preview="\"$differ\"" \
            --preview-window="left:`misc.preview.width`:noborder" \
            --prompt="'add to $branch > '")"

    to_add="$(
        printf "$result" | tabulate -i 2 | \
        sort --human-numeric-sort | \
        eval $UNIQUE_SORT | eval $LINES_TO_LINE)"

    if [ -n "$to_add" ]; then
        state="$(git.this.state)"

        if [ -z "$state" ]; then
            prefix=""
            [[ "$branch" =~ "^[0-9A-Za-z-]+$" ]] && prefix="$branch: "
            command="git add $to_add && git commit -m \"$prefix"

            [ -n "$BUFFER" ] && command="$BUFFER && $command"
            LBUFFER="$command"
            RBUFFER='"'
        else
            LBUFFER=" git add $to_add"
            RBUFFER=""
        fi
    fi

    zle reset-prompt
    zle redisplay
    return "$retval"
}
zle -N __widget.git.add


function __widget.git.checkout_modified {
    local branch commit result

    git.this.root 1>/dev/null 2>/dev/null || return true
    branch="$(git.this.branch)" || return "$?"

    local differ="$SHELL $DIFF_SHOW_OR_CONTENT '$branch' {2} | $CMD_DELTA"
    result="$(
        git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-files | \
        eval $ESCAPE_STATUS | eval $FZF \
            --filepath-word --tac --multi --with-nth=1.. --nth=2.. \
            --preview="\"$differ\"" \
            --preview-window="left:`misc.preview.width`:noborder" \
            --prompt="'revert $branch > '")"

    to_remove="$(
        printf "$result" | \
        grep -P '^\?\?' | tabulate -i 2 | \
        sort --human-numeric-sort | \
        eval $UNIQUE_SORT | eval $LINES_TO_LINE)"

    to_checkout="$(
        printf "$result" | \
        grep -Pv '^\?\?' | tabulate -i 2 | \
        sort --human-numeric-sort | \
        eval $UNIQUE_SORT | eval $LINES_TO_LINE)"

    if [ -n "$to_remove" ] || [ -n "$to_checkout" ]; then

        local command=""
        if [ -n "$to_remove" ]; then
            command="unlink $to_remove"
        fi

        if [ -n "$to_checkout" ]; then
            if [ -z "$command" ]; then
                command="git checkout $branch -- $to_checkout"
            else
                command="$command && git checkout $branch -- $to_checkout"
            fi
        fi

        [ -n "$BUFFER" ] && local command="$BUFFER &&"
        LBUFFER="$command"
    fi

    zle reset-prompt
    zle redisplay
    return "$retval"
}
zle -N __widget.git.checkout_modified


function __widget.git.merge_branch {
    local branch commit result state

    git.this.root 1>/dev/null 2>/dev/null || return true
    git.is_clean >/dev/null || state='(dirty) '
    branch="$(git.this.branch)" || return "$?"

    local differ="echo {} | sed 's: +$::' | sed 's:^*::' | tabulate -i 1 | xargs -I$ $SHELL $DIFF_SHOW $commit $ | $CMD_DELTA"
    local result="$(
        git for-each-ref --sort=-committerdate refs/heads/ --color=always --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" | \
        eval "$FZF --preview=\"$differ\" --preview-window=\"left:`misc.preview.width`:noborder\" --prompt=\"rebase $branch $state> \""
    )"

    result="$(
        echo "$result" | \
        sed -z 's:^*::g' | sed -z 's:^ ::g' | \
        tabulate -i 1
    )" || return "$?"

    if [ -n "$result" ]; then
        local command="$(git.cmd.fetch "$result") && git merge --no-commit \"origin/$result\""

        if [ -z "$BUFFER" ]; then
            LBUFFER=" $command"
        else
            LBUFFER="$BUFFER && $command"
        fi
    fi

    zle reset-prompt
    return 0
}
zle -N __widget.git.merge_branch


function __widget.git.rebase_branch {
    local branch commit result state

    git.this.root 1>/dev/null 2>/dev/null || return true
    git.is_clean >/dev/null || state='(dirty!) '
    branch="$(git.this.branch)" || return "$?"

    local differ="echo {} | sed 's: +$::' | sed 's:^*::' | tabulate -i 1 | xargs -I$ $SHELL $DIFF_SHOW $commit $ | $CMD_DELTA"
    local result="$(
        git for-each-ref --sort=-committerdate refs/heads/ --color=always --format="%(HEAD) %(color:yellow bold)%(refname:short)%(color:reset) %(contents:subject) %(color:black bold)%(authoremail) %(committerdate:relative)" | \
        eval "$FZF --preview=\"$differ\" --preview-window=\"left:`misc.preview.width`:noborder\" --prompt=\"rebase $branch $state> \""
    )"

    result="$(
        echo "$result" | \
        sed -z 's:^*::g' | sed -z 's:^ ::g' | \
        tabulate -i 1
    )" || return "$?"

    if [ -n "$result" ]; then
        local command="$(git.cmd.fetch "$result") && git rebase --stat --interactive --no-autosquash --autostash \"origin/$result\""

        if [ -z "$BUFFER" ]; then
            LBUFFER=" $command"
        else
            LBUFFER="$BUFFER && $command"
        fi
    fi

    zle reset-prompt
    return 0
}
zle -N __widget.git.rebase_branch


function __widget.git.show_commits {
    local branch commit result

    git.this.root 1>/dev/null 2>/dev/null || return true
    branch="$(git.this.branch)" || return "$?"
    result="$(git_list_commits | \
        eval "$FZF --prompt=\"checkout > \" --preview-window=\"left:`misc.preview.width`:noborder\" --preview=\"echo {} | $CMD_EXTRACT_COMMIT | $CMD_XARGS_SHOW_TO_COMMIT\""
    )" || return "$?"

    if [ -n "$result" ]; then
        commit="$(run.out "echo '$result' | $CMD_EXTRACT_COMMIT")" || return "$?"

        if [ -z "$commit" ]; then
            zle reset-prompt
            return 1
        fi

        if [ -n "$BUFFER" ]; then
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
}
zle -N __widget.git.show_commits


function __widget.git.checkout_commit {
    local branch commit result

    git.this.root 1>/dev/null 2>/dev/null || return true
    branch="$(git.this.branch)" || return "$?"
    result="$(eval "git_list_commits $branch" | sed 1d | GLOB_PIPE_NUMERATE | \
        eval "$FZF --prompt=\"checkout > \" --preview-window=\"left:`misc.preview.width`:noborder\" --preview=\"echo {} | $CMD_EXTRACT_COMMIT | $CMD_XARGS_DIFF_TO_COMMIT\""
    )" || return "$?"

    if [ -n "$result" ]; then
        commit="$(run.out "echo '$result' | $CMD_EXTRACT_COMMIT")" || return "$?"

        if [ -z "$commit" ]; then
            zle reset-prompt
            return 1
        fi

        if [ -n "$BUFFER" ]; then
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
}
zle -N __widget.git.checkout_commit


function __widget.git.checkout_tag {
    local branch commit result

    git.this.root 1>/dev/null 2>/dev/null || return true
    branch="$(git.this.branch)" || return "$?"
    result="$(git_list_tags | \
        eval "$FZF --prompt=\"checkout > \" --preview-window=\"left:`misc.preview.width`:noborder\" --preview=\"echo {} | $CMD_EXTRACT_COMMIT | $CMD_XARGS_DIFF_TO_COMMIT\""
    )" || return "$?"

    if [ -n "$result" ]; then
        commit="$(run.out "echo '$result' | $CMD_EXTRACT_COMMIT")" || return "$?"

        if [ -z "$commit" ]; then
            zle reset-prompt
            return 1
        fi

        if [ -n "$BUFFER" ]; then
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
}
zle -N __widget.git.checkout_tag
