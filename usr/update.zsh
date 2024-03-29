autoload -Uz async && async


function is_workhours {
    local head="${ASH_WORKHOUR_START:-6}"
    local tail="${ASH_WORKHOUR_END:-16}"

    local current_hour="$(builtin strftime '%H' $EPOCHSECONDS)"
    if [ "$current_hour" -ge "$head" ] && [ "$current_hour" -lt "$tail" ]; then
        return 0
    fi
    return 1
}


function __fetch_updates_background {
    if [ -z "$ASH" ]; then
        fail $0 "ASH:'$ASH' isn't accessible"
        return 1
    fi
    local cwd="$PWD"

    builtin cd "$ASH"
    if [ "$(grep --count -P "fetch.+remotes/origin/\*" .git/config)" -eq 0 ]; then
        git remote set-branches --add origin "*"
    fi
    git fetch --jobs=4 --all --tags --prune --prune-tags --quiet 2>/dev/null
    builtin cd "$cwd"
    return "$?"
}


function __get_updates_count {
    if [ ! -x "$ASH" ]; then
        fail $0 "ASH:'$ASH' isn't accessible"
        return 1

    elif [ -z "$ASH_CACHE" ]; then
        fail $0 "ASH_CACHE:'$ASH_CACHE' isn't accessible"
        return 2
    fi

    local file="$ASH_CACHE/last-fetch"

    local last_check="$(cat $file 2>/dev/null)"
    [ -z "$last_check" ] && local last_check="0"

    let fetch_every="${ASH_UPDATES_FETCH_H:-1} * 3600"
    let need_check="$EPOCHSECONDS - $fetch_every > $last_check"

    if [ "$need_check" -eq 0 ]; then
        echo 0
        return 0
    fi

    local last_fetch="$(fs.mtime "$ASH/.git/FETCH_HEAD" 2>/dev/null)"
    let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"

    local cwd="$PWD"
    builtin cd "$ASH"

    local branch="$(git.this.branch)"
    if [ -z "$branch" ]; then
        builtin cd "$cwd"
        fail $0 "cannot detect branch: '$branch' - empty"
        return 3
    fi

    local count="$(
        git rev-list --left-right --first-parent \
        origin/$branch...$branch 2>/dev/null \
        | grep -P '^<' | wc -l \
    )"

    if [ "$need_fetch" -gt 0 ]; then
        source "$ZSH/custom/plugins/zsh-async/async.zsh"
        async_start_worker updates_fetcher
        async_job updates_fetcher __fetch_updates_background
    fi

    [ ! -d "`fs.dirname "$file"`" ] && mkdir -p "`fs.dirname "$file"`"
    echo "$EPOCHSECONDS" > "$file"
    [ -z "$count" ] && echo 0 || echo "$count"
    builtin cd "$cwd"
}


function check_updates {
    local updates

    if [ ! -x "$ASH" ]; then
        fail $0 "ASH:'$ASH' isn't accessible"
        return 1

    elif [ -z "$ASH_CACHE" ]; then
        fail $0 "ASH_CACHE:'$ASH_CACHE' isn't accessible"
        return 2
    fi
    unset ASH_UPDATES_COUNT

    updates="$(__get_updates_count)"
    [ "$?" -gt 0 ] && return 1
    [ "$updates" -eq 0 ] && return 0

    local file="$ASH_CACHE/last-update"
    local last_check="$(cat $file 2>/dev/null)"
    [ -z "$last_check" ] && local last_check="0"

    let check_every=" ${ASH_UPDATES_REPORT_D:-1} * 86400"
    let need_check="$EPOCHSECONDS - $check_every > $last_check"
    [ "$need_check" -eq 0 ] && return 0

    local cwd="$PWD" && builtin cd "$ASH"
    git.is_clean
    if [ "$?" -gt 0 ]; then
        builtin cd "$cwd"
        return 2
    fi

    local branch="$(git.this.branch)"
    if [ "$branch" = "develop" ]; then
        info $0 "$updates new commits found, let's go!"
        ash.pull "$branch"
        info $0 "commits applied, please run: exec zsh; for partial (fast) update run: ash.update; for install (full) all updates: ash.upgrade\n" >&2

    elif [ "$branch" = "stable" ]; then
        local last_commit="$(git --git-dir="$ASH/.git" --work-tree="$ASH/" log -1 --format="%ct")"
        let wait_stable=" ${ASH_UPDATES_STABLE_STAY_D:-7} * 86400"
        let need_check="$EPOCHSECONDS - $wait_stable > $last_commit"
        [ "$need_check" -eq 0 ] && return 0
    fi

    ASH_UPDATES_COUNT="$updates"
    [ ! -d "$ASH_CACHE" ] && mkdir -p "$ASH_CACHE"
    echo "$EPOCHSECONDS" > "$file"
    echo "$branch"
}


function motd {
    local branch="$(check_updates)"

    if [ -n "$TMUX" ]; then
        return 0

    elif [ -z "$branch" ]; then
        return 0

    elif [ -z "$ASH_UPDATES_COUNT" ]; then
        return 0

    elif [ "$ASH_UPDATES_COUNT" -eq 0 ]; then
        return 0

    fi

    local cwd="$PWD" && builtin cd "$ASH"
    local ctag="$(git describe --tags --abbrev=0 2>/dev/null)"
    local ftag="$(git --no-pager log --oneline --no-walk --tags="?.?.?" --format="%d" | grep -Po '\d+\.\d+\.\d+' | proximity-sort - | tail -n 1)"
    local last_commit="$(git log -1 --format="at %h updated %cr" 2>/dev/null)"
    builtin cd "$cwd"

    if [ "$branch" = 'master' ]; then
        if [ "$ctag" ] && [ "$ctag" != "$ftag" ]; then
            info $0 "v$ctag (updates to v$ftag downloaded), just run: run: ash.upgrade, then: exec zsh"
        fi

    elif [ "$branch" = 'develop' ]; then
        info $0 "v$ctag $branch $last_commit."

    else
        info $0 "v$ctag $branch $last_commit, found $ASH_UPDATES_COUNT updates, run: ash.upgrade, then: exec zsh"

    fi
}
