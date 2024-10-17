local GET_ROOT='git rev-parse --quiet --show-toplevel'
local GET_HASH='git rev-parse --quiet --verify HEAD 2>/dev/null'
local GET_BRANCH='git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null'

# command line batch generators

function git.cmd.checkout.verb.uncached {
    local result
    result="$(git switch 2>&1 | grep 'is not a git command' | wc -l)" || return "$?"
    if [ "$result" -gt 0 ]; then
        echo 'checkout'
    else
        echo 'switch'
    fi
}


function git.cmd.checkout.verb {
    result="$(eval.cached `fs.lm.dirs "$ASH/bin"` git.cmd.checkout.verb.uncached)"
    if [ "$?" -gt 0 ] || [ -z "$result" ]; then
        result='checkout'
    fi
    printf "$result"
}


function git.cmd.checkout {
    if [ -z "$1" ]; then
        fail $0 "\$1 - branch required"
        return 1

    elif [[ "$1" =~ '^[0-9]+' ]]; then
        if [ -n "$ASH_BRANCH_PREFIX" ]; then
            local branch="$ASH_BRANCH_PREFIX-$1"
        else
            fail $0 "branch name can't starts by digit"
            return 2
        fi
    else
        local branch="$1"
    fi
    verb="$(git.cmd.checkout.verb)"
    echo "git checkout -b \"$branch\" 2>/dev/null || git $verb \"$branch\""
}

function git.cmd.fetch {
    local branch
    branch="$(git.this.branch)" || return "$branch"
    [ -z "$branch" ] && return 1

    local function __temp() {
        echo "git fetch origin \"$1\":\"$1\" 2>&1"
    }

    local cmd=''
    for arg in $@; do
        if [ "$arg" = "$branch" ]; then
            continue
        elif [ -n "$cmd" ]; then
            local cmd="$cmd && `__temp $arg`"
        else
            local cmd="`__temp $arg`"
        fi
    done
    unset __temp

    if [ -n "$cmd" ]; then
        local cmd="$cmd && git fetch --tags --force"
    else
        local cmd="git fetch --tags --force"
    fi
    echo "$cmd"
}

function git.cmd.pull {
    local branch
    branch="${1:-$(git.this.branch)}" || return "$branch"
    [ -z "$branch" ] && return 1
    echo "git pull --ff-only --no-edit --no-commit origin $branch"
}

function git.cmd.pullmerge {
    local branch
    branch="${1:-$(git.this.branch)}"
    if [ "$?" -gt 0 ] || [ -z "$branch" ]; then
        return 1
    fi
    echo "git pull --no-edit --no-commit origin $branch"
}

# core functions

function git.this.root {
    local cwd result submodule

    if [ -z "$1" ]; then
        result="$(git rev-parse --quiet --show-toplevel)" || return "$?"

    else
        if [ -d "$1" ]; then
            cwd="$PWD"
            builtin cd "$1"

            result="$(git.this.root)" || return "$?"
            builtin cd "$cwd"

        else
            fail $0 "path '$1' isn't acessible"
            return 1
        fi
    fi

    if [ ! -d "$result" ]; then
        return 127

    elif [ -d "$result/.git" ]; then
        result="$result/.git"

    elif [ -f "$result/.git" ]; then
        submodule="$(cat "$result/.git" | grep -P 'gitdir: ' | sd '^gitdir: ' '')" || return "$1"

        if [ ! -d "$result/$submodule" ]; then
            fail $0 "path '$result' exists, but '$result/$submodule' isn't"
            return 2
        fi
        result="$result/$submodule"
    fi

    result="$(fs.realpath "$result")" || returl "$?"
    printf "$result"
}

function git.root {
    local result
    result="$(git.this.root)" || return "$?"
    [ -z "$result" ] && return 1

    result="$(fs.dirname "$result")" || return "$?"
    [ -z "$result" ] && return 1

    printf "$result"
}

function git.this.hash {
    local result
    result="$(eval "$GET_HASH")" || return "$?"
    [ -z "$result" ] && return 1
}

function git.this.branch {
    local result
    result="$(eval $GET_BRANCH)" || return "$?"
    if [ -z "$result" ]; then
        return 1

    elif [ "$result" = "HEAD" ]; then
        if [ -z "$(git name-rev --name-only HEAD 2>&1 | grep -Pv '^(Could not get sha1)')" ]; then
            warn $0 "empty repository $(git.this.root) without any commits?"
            local result="$(git symbolic-ref --short HEAD)"
        fi
    fi
    echo "$result"
}

function git.this.state {
    local root
    root="$(git.this.root 2>/dev/null)" || return "$?"
    [ -z "$root" ] && return 1

    if [ -d "$root/rebase-merge" ] || [ -d "$root/rebase-apply" ]; then
        local state="rebase"

    elif [ -f "$root/CHERRY_PICK_HEAD" ]; then
        local state="cherry-pick"

    elif [ -f "$root/MERGE_HEAD" ]; then
        local state="merge"
    fi

    [ -z "$state" ] && return 1
    echo "$state"
}

# just functions

function git.branch.delete.force {
    if [ -z "$1" ]; then
        fail $0 "\$1 - branch required"
        return 1
    fi
    draw.cmd "git branch -D $1 && git push origin --delete $1"
    return $?
}

function git.branch.rename {
    if [ -n "$2" ]; then
        if [ "$1" = "$2" ]; then
            fail $0 "source and target branch names must be different"
            return 1
        fi
        local src="$1"
        local dst="$2"

    elif [ -n "$1" ]; then
        local dst="$1"
        local src
        src="$(git.this.branch)"
        if [ "$?" -gt 0 ] || [ -z "$src" ]; then
            return 2
        fi
    else
        fail $0 "old_name new_name or just new_name (rename current) "
        return 3
    fi
    draw.cmd "git branch -m $src $dst && git push origin :$src $dst"
}

function git.checkout.actual {
    local result
    result="$(git.this.branch)" || return "$?"
    [ -z "$result" ] && return 1

    git.pull.reset "$result" || return "$?"
    git.checkout.current $*
}

function git.checkout.current {
    local result
    result="$(git.cmd.checkout $*)" || return "$?"
    [ -z "$result" ] && return 1

    run.show "$result"
    return "$?"
}

function git.fetch {
    local result

    result="$(git.cmd.fetch $@)" || return "$?"
    [ -z "$result" ] && return 1

    run.show "$result"
    return "$?"
}

function git.fetch.merge {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1

    git.fetch "$result"
    [ "$?" -gt 0 ] && return 2

    run.show "git merge origin/$result"
    return "$?"
}

function git.branch.select {
    local result

    [ -z "$1" ] && return 1
    result="$(git.this.branch)" || return "$?"

    if [ -z "$result" ]; then
        return 1
    elif [ "$1" = "$result" ]; then
        return 2
    fi

    [ -z "$(git.this.root)" ] && return 3

    local cmd="git fetch origin '$1':'$1' && git.is_clean && git checkout --force --quiet '$1' && git reset --hard '$1' && git pull origin '$1' && git.mtime.set"
    run.show "$cmd"
    return "$?"
}

function git.branch.tag {
    if [ -z "$1" ]; then
        fail $0 "tag required"
        return 1

    elif [ -n "$2" ]; then
        local tag="$2"
        local branch="$1"

    else
        local tag="$1"
        local branch
        branch="$(git.this.branch)"
        if [ "$?" -gt 0 ] || [ -z "$branch" ]; then
            fail $0 "branch couldn't detected"
            return 2
        fi
    fi

    info $0 "$branch/$tag"

    git.is_clean           || return "$?"
    git checkout "$branch" || return "$?"
    git.pull "$branch"     || return "$?"
    git.tag.set "$tag"
    return "$?"
}

function git.pull {
    local result
    result="$(git.cmd.pull $@)" || return "$?"
    [ -z "$result" ] && return 1

    run.show "$result" 2>&1 | grep -v 'up to date'
    local retval="$?"
    git.mtime.set 2>&1
    return "$retval"
}

function git.pull.merge {
    local result
    result="$(git.cmd.pullmerge $@)" || return "$?"
    [ -z "$result" ] && return 1

    run.show "$result" 2>&1 | grep -v 'up to date'
    local retval="$?"
    git.mtime.set 2>&1
    return "$retval"
}

function git.pull.reset {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1

    git.is_clean                               || return "$?"
    git.fetch "$result"                        || return "$?"
    run.show "git reset --hard origin/$result" || return "$?"
    git.pull $result
    return "$?"
}

function git.push {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1

    run.show "git push origin $result"
    return "$?"
}

function git.push.force {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1

    run.show "git push --force origin $result"
    return $?
}

function git.mtime.set {
    local result worktree
    if [ -x "$(which git-restore-mtime)" ]; then

        result="${1:-$(git.this.root 2>/dev/null)}" || return "$?"
        [ -z "$result" ] && return 1

        worktree="$(git config --file "$result/config" core.worktree)"
        if [ "$?" -eq 0 ] && [ -n "$worktree" ]; then
            if [ ! -d "$result/$worktree" ]; then
                fail "$0" "something went wrong: '$worktree'; '$result'"
                return 127
            fi
            worktree="$(fs.realpath "$result/$worktree")" || return "$?"

        else
            if [ -z "$worktree" ] && [ -d "$result" ]; then
                worktree="$(fs.dirname "$result")"
            else
                fail "$0" "something went wrong: '$worktree'; '$result'"
                return 255
            fi
        fi

        git-restore-mtime --skip-missing --work-tree "$worktree/" --git-dir "$result/" "$worktree/" 1>&2
        return "$?"
    fi
    return 2
}

function git.is_clean {
    local root result
    if [ -z "$1" ]; then
        root="$(git.this.root)"
    else
        root="$(git.this.root "$1")"
    fi

    if [ "$?" -eq 2 ] && [ -z "$root" ]; then
        return 0
    fi

    result="$(git ls-files --deleted --modified --exclude-standard `git rev-parse --show-toplevel`)" || return "$?"

    if [ -n "$result" ]; then
        warn $0 "$root isn't clean: $result"
        return 1
    fi
}

function git.tag.set {
    if [ -z "$1" ]; then
        fail $0 "\$1 - tag required"
        return 1
    fi
    run.show "git tag -a $1 -m \"$1\" && git push --tags && git fetch --tags --force"
    return "$?"
}

function git.tag.unset {
    if [ -z "$1" ]; then
        fail $0 "\$1 - tag required"
        return 1
    fi
    run.show "git tag -d \"$1\" && git push --delete origin \"$1\""
    return "$?"
}

# user helpers

function git.branch.delete {
    local cmd result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1


    cmd="git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D \"$result\" && git remote prune origin"

    if [ "$result" = "master" ] || [ "$result" = "develop" ]; then
        draw.cmd "$cmd && git push origin --delete $result"
        fail $0 "'$result' is protected"
        return 2
    fi

    git.is_clean || return "$?"

    run.show "$cmd"
    draw.cmd "git push origin --delete $result"
    return "$?"
}

function git.branch.DELETE.REMOTE {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1


    if [ "$result" = "master" ] || [ "$result" = "develop" ]; then
        fail $0 "'$result' is protected"
        return 2
    fi

    git.is_clean || return "$?"

    run.show "git reset --hard && (git checkout develop 2>/dev/null 1>/dev/null 2> /dev/null || git checkout master 2>/dev/null 1>/dev/null) && git branch -D \"$result\" && git push origin --delete \"$result\" || true && git remote prune origin"
    return "$?"
}

function git.squash.pushed {
    local result
    result="${1:-$(git.this.branch)}" || return "$?"
    [ -z "$result" ] && return 1


    result="$(
        git show-branch | grep '*' | \
        grep -v "`git rev-parse --abbrev-ref HEAD`" | \
        head -n 1 | sd '^(.+)\[' '' | tabulate -d '] ' -i 1)"

    if [ "$?" -gt 0 ] || [ -z "$result" ]; then
        return 2
    fi
    run.show "git rebase --interactive --no-autosquash --no-autostash --strategy=recursive --strategy-option=ours --strategy-option=diff-algorithm=histogram \"$result\""
}

function git.nested {
    local branch root
    root="$(fs.realpath "${1:-.}")" || return "$?"
    if [ ! -d "$root" ]; then
        fail $0 "working path '$root' isn't accessible"
        return 1
    fi

    local cwd="$PWD"

    local header=""
    local mtime="$(which git-restore-mtime 2>/dev/null)"

    local realpath="$(which grealpath)"
    if [ ! -x "$realpath" ]; then
        local realpath="$(which realpath)"
    fi

    find "$root" -maxdepth 2 -type d -name .git | sort | while read git_directory
    do
        current_path="$(fs.dirname "$(fs.realpath $git_directory)")"

        if [ -z "$header" ] && [ "$root" != "$current_path" ]; then
            builtin cd "$root"
            if [ -x "$commands[git-summary]" ]; then
                git-summary --quiet --hidden --parallel "$(misc.cpu.count)"
            else
                PRE=1 warn $0 "update '$(fs.realpath "$root")'"
            fi
            local header="1"
        fi

        if [ -x "$realpath" ]; then
            local show_path="$($realpath --relative-to="$(fs.dirname "$root")" "$current_path")"
        else
            local show_path="$current_path"
        fi

        builtin cd "$current_path"
        branch="$(git.this.branch)"
        if [ "$?" -gt 0 ] || [ -z "$branch" ]; then
            warn $0 "something went wrong in '$current_path', skip"
            builtin cd "$cwd"
            continue

        elif [[ "$branch" -regex-match '^(master|develop|stable)' ]]; then
            POST=0 info $0 "$show_path: $branch.. "
        else
            POST=0 warn $0 "$show_path: $branch.. "
        fi

        local cmd="git fetch origin master && git fetch --tags --force"
        if git.is_clean 2>/dev/null; then

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

        eval.run "$cmd" 1>/dev/null 2>/dev/null
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
