local GET_ROOT='git rev-parse --quiet --show-toplevel'
local GET_HASH='git rev-parse --quiet --verify HEAD 2>/dev/null'
local GET_BRANCH='git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null'

# command line batch generators

function cmd_git_checkout {
    if [ -z "$1" ]; then
        fail $0 "branch required"
        return 1

    elif [[ "$1" =~ '^[0-9]+' ]]; then
        if [ -n "$JOSH_BRANCH_PREFIX" ]; then
            local branch="$JOSH_BRANCH_PREFIX-$1"
        else
            fail $0 "branch name doens't start with digit"
            return 2
        fi

    else
        local branch="$1"
    fi

    echo "git checkout -b \"$branch\" 2>/dev/null || git switch \"$branch\""
}

function cmd_git_fetch {
    local branch="`git_current_branch`"
    [ -z "$branch" ] && return 1

    local function git_fetch_make_cmd() {
        echo "git fetch origin \"$1\":\"$1\" 2>&1"
    }

    local cmd=''
    for arg in $@; do
        if [ "$arg" = "$branch" ]; then
            continue
        elif [ -n "$cmd" ]; then
            local cmd="$cmd && `git_fetch_make_cmd $arg`"
        else
            local cmd="`git_fetch_make_cmd $arg`"
        fi
    done
    unset git_fetch_make_cmd

    if [ -n "$cmd" ]; then
        local cmd="$cmd && git fetch --tags"
    else
        local cmd="git fetch --tags"
    fi
    echo "$cmd"
}

function cmd_git_pull {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1
    echo "git pull --ff-only --no-edit --no-commit origin $branch"
}

function cmd_git_pull_merge {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1
    echo "git pull --no-edit --no-commit origin $branch"
}

# core functions

function git_root {
    if [ -z "$1" ]; then
        local result="$(fs_realpath `eval "$GET_ROOT 2>/dev/null"`)"
        local retval="$?"
    else
        if [ -d "$1" ]; then
            local cwd="$PWD"
            builtin cd "$1"
            local result="$(git_root)"
            local retval="$?"
            builtin cd "$cwd"

        else
            fail $0 "path '$1' isn't acessible"
            return 1
        fi
    fi
    if [ "$retval" -eq 0 ] && [ -d "$result" ]; then
        echo "$result"
    else
        return "$retval"
    fi
}

function git_current_hash {
    local result="`eval $GET_HASH`"
    [ "$result" ] && echo "$result"
}

function git_current_branch {
    local result="`eval $GET_BRANCH`"
    if [ "$result" = "HEAD" ]; then
        if [ ! "`git name-rev --name-only HEAD 2>&1 | grep -Pv '^(Could not get sha1)'`" ]; then
            echo " - empty repository `git_root` without any commits?" >&2
            local result="`git symbolic-ref --short HEAD`"
        fi
    fi
    [ -n "$result" ] && echo "$result"
}

function get_repository_state {
    local root="`git_root 2>/dev/null`"
    [ -z "$root" ] && return 1

    if [ -d "$root/.git/rebase-merge" ] || [ -d "$root/.git/rebase-apply" ]; then
        local state="rebase"

    elif [ -f "$root/.git/CHERRY_PICK_HEAD" ]; then
        local state="cherry-pick"

    elif [ -f "$root/.git/MERGE_HEAD" ]; then
        local state="merge"
    fi

    [ -z "$state" ] && return 1
    echo "$state"
}

# just functions

function git_branch_delete {
    if [ -z "$1" ]; then
        fail $0 "branch required"
        return 1
    fi
    run_show "git branch -D $1 && git push origin --delete $1"
    return $?
}

function git_branch_rename {
    if [ -n "$2" ]; then
        if [ "$1" = "$2" ]; then
            fail $0 "source and target branch names must be different"
            return 1
        fi
        local src="$1"
        local dst="$2"

    elif [ -n "$1" ]; then
        local dst="$1"
        local src="`git_current_branch`"
        [ -z "$src" ] && return 2
    else
        fail $0 "old_name new_name or just new_name (rename current) "
        return 3
    fi
    echo "git branch -m $src $dst && git push origin :$src $dst"
}

function git_checkout_from_actual {
    local branch="`git_current_branch`"
    [ -z "$branch" ] && return 1

    git_pull_reset "$branch" || return 2
    git_checkout_from_current $*
}

function git_checkout_from_current {
    local cmd="`cmd_git_checkout $@`"
    [ -z "$cmd" ] && return 1
    run_show "$cmd"
    return $?
}

function git_fetch {
    local cmd="`cmd_git_fetch $@`"
    [ -z "$cmd" ] && return 1
    run_show "$cmd" 2>&1 | grep -v 'up to date'
    return $?
}

function git_fetch_merge {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1

    git_fetch $branch; [ $? -gt 0 ] && return 2
    run_show "git merge origin/$branch"
    return $?
}

function git_fetch_checkout_branch {
    [ -z "$1" ] && return 1

    local branch="`git_current_branch`"
    if [ -z "$branch" ] || [ "$1" = "$branch" ]; then
        return 2
    fi

    local root="`git_root`"
    [ -z "$root" ] && return 3

    local cmd="git fetch origin \"$1\":\"$1\" && git_repository_clean && git checkout --force --quiet $1 && git reset --hard $1 && git pull origin $1"
    run_show "$cmd"
    return $?
}

function git_set_branch_tag {
    if [ -z "$1" ]; then
        fail $0 "tag required"
        return 1

    elif [ -n "$2" ]; then
        local tag="$2"
        local branch="$1"

    else
        local tag="$1"
        local branch="`git_current_branch`"
        if [ -z "$branch" ]; then
            fail $0 "branch couldn't detected"
            return 2
        fi
    fi

    info $0 "$branch/$tag"

    git_repository_clean;   [ $? -gt 0 ] && return 3
    git checkout "$branch"; [ $? -gt 0 ] && return 4
    git_pull "$branch";     [ $? -gt 0 ] && return 5
    git_set_tag "$tag"
    return $?
}

function git_pull {
    local cmd="`cmd_git_pull $@`"
    [ -z "$cmd" ] && return 1
    run_show "$cmd" 2>&1 | grep -v 'up to date'
    local retval="$?"
    git_rewind_time 2>&1
    return "$retval"
}

function git_pull_merge {
    local cmd="`cmd_git_pull_merge $@`"
    [ -z "$cmd" ] && return 1
    run_show "$cmd" 2>&1 | grep -v 'up to date'
    local retval="$?"
    git_rewind_time 2>&1
    return "$retval"
}

function git_pull_reset {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1

    git_repository_clean;                       [ $? -gt 0 ] && return 2
    git_fetch $branch;                          [ $? -gt 0 ] && return 3
    run_show "git reset --hard origin/$branch"; [ $? -gt 0 ] && return 4
    git_pull $branch
    return $?
}

function git_push {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1
    run_show "git push origin $branch"
    return $?
}

function git_push_force {
    local branch="${1:-`git_current_branch`}"
    [ -z "$branch" ] && return 1
    run_show "git push --force origin $branch"
    return $?
}

function git_rewind_time {
    if [ -x "`which git-restore-mtime`" ]; then
        local root="`git_root 2>/dev/null`"
        [ -z "$root" ] && return 2
        git-restore-mtime --skip-missing --work-tree "$root/" --git-dir "$root/.git/" "$root/"
    fi
}

function git_repository_clean {
    if [ -z "$1" ]; then
        local root="$(git_root)"
    else
        local root="$(git_root "$1")"
    fi

    [ ! "$root" ] && return 0

    local modified='echo $(git ls-files --modified `git rev-parse --show-toplevel`)$(git ls-files --deleted --others --exclude-standard `git rev-parse --show-toplevel`)'

    if [ -n "$($SHELL -c "$modified")" ]; then
        warn $0 "$root isn't clean"
        return 1
    fi
}

function git_set_tag {
    if [ -z "$1" ]; then
        fail $0 "tag required"
        return 1
    fi
    run_show "git tag -a $1 -m \"$1\" && git push --tags && git fetch --tags"
    return $?
}

function git_unset_tag {
    if [ -z "$1" ]; then
        fail $0 "tag required"
        return 1
    fi
    run_show "git tag -d \"$1\" && git push --delete origin \"$1\""
    return $?
}

# user helpers

function drop_this_branch_right_now {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    if [ "$branch" = "master" ] || [ "$branch" = "develop" ]; then
        fail $0 "can't delete $branch branch!"
        return 2
    fi

    git_repository_clean; [ $? -gt 0 ] && return 3

    run_show "git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D \"$branch\" && git remote prune origin"
    printf " => git push origin --delete $branch\n" >&2
    return $?
}

function DROP_THIS_BRANCH_RIGHT_NOW {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    if [ "$branch" = "master" ] || [ "$branch" = "develop" ]; then
        fail $0 "can't delete $branch branch!"
        return 2
    fi

    git_repository_clean; [ $? -gt 0 ] && return 3

    run_show "git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D \"$branch\" && git push origin --delete \"$branch\" || true && git remote prune origin"
    return $?
}

function git_squash_already_pushed {
    local branch="${1:-`git_current_branch`}"
    [ ! "$branch" ] && return 1

    local parent="$(git show-branch | grep '*' | grep -v "`git rev-parse --abbrev-ref HEAD`" | head -n 1 | sd '^(.+)\[' '' | tabulate -d '] ' -i 1)"
    [ ! "$parent" ] && return 2

    run_show "git rebase --interactive --no-autosquash --no-autostash --strategy=recursive --strategy-option=ours --strategy-option=diff-algorithm=histogram \"$parent\""
}

function git_update_nested_repositories {
    local cwd="$PWD"
    local root="$(fs_realpath "${1:-.}")"

    if [ ! -d "$root" ]; then
        fail $0 "working path '$root' isn't accessible"
        return 1
    fi

    local header=""
    local mtime="$(which git-restore-mtime)"

    find "$root" -maxdepth 2 -type d -name .git | sort | while read git_directory
    do
        current_path="$(fs_dirname "$(fs_realpath $git_directory)")"

        if [ -z "$header" ] && [ "$root" != "$current_path" ]; then
            PRE=2 info $0 "update '$(fs_realpath "$root")'"
            if [ -x "$(which gfold)" ]; then
                gfold -d classic
            fi
            printf "\n" >&2
            local header="1"
        fi

        builtin cd "$current_path"
        local branch="`$SHELL -c "$GET_BRANCH"`"
        if [ "$?" -gt 0 ] || [ -z "$branch" ]; then
            warn $0 "something went wrong in '$current_path', skip"
            builtin cd "$cwd"
            continue
        fi

        POST=0 info $0 "$branch in '$current_path'.. "
        local cmd="git fetch origin master && git fetch --tags"

        if git_repository_clean 2>/dev/null; then

            if [ "$branch" != "master" ]; then
                printf "fetch, reset and pull '$branch'.. " >&2
                local cmd="$cmd && git fetch origin \"$branch\" && git reset --hard \"origin/$branch\" && git pull origin \"$branch\""

            else
                printf "reset and pull '$branch'.. " >&2
                local cmd="$cmd && git reset --hard \"origin/$branch\" && git pull origin \"$branch\""
            fi

        else
            if [ "$branch" != "master" ]; then
                printf "unclean, just fetch '$branch'.. " >&2
                local cmd="$cmd && git fetch origin \"$branch\""
            else
                printf "unclean, just fetch '$branch'.. " >&2
            fi
        fi

        eval.retval "$cmd" 1>/dev/null 2>/dev/null
        if [ "$?" -eq 0 ]; then
            printf "ok\n" >&2
        else
            printf "err\n" >&2
        fi

        if [ -x "$mtime" ]; then
            git-restore-mtime --skip-missing 2>/dev/null
        fi

        builtin cd "$cwd"
    done
}
