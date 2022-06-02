zmodload zsh/datetime
autoload -Uz async && async


function is_workhours {
    local head="${JOSH_WORKHOUR_START:-6}"
    local tail="${JOSH_WORKHOUR_END:-16}"

    local current_hour="`builtin strftime '%H' $EPOCHSECONDS`"
    if [ "$current_hour" -ge "$head" ] && [ "$current_hour" -lt "$tail" ]; then
        return 0
    fi
    return 1
}


function fetch_updates_background {
    if [ -z "$JOSH" ]; then
        echo " - $0 warning: JOSH:\`$JOSH\`" >&2
        return 1
    fi
    local cwd="$PWD"

    builtin cd "$JOSH"
    if [ "`grep --count -P "fetch.+remotes/origin/\*" .git/config`" -eq 0 ]; then
        git remote set-branches --add origin "*"
    fi
    git fetch --jobs=4 --all --tags --prune --prune-tags --quiet 2>/dev/null
    builtin cd "$cwd"
    return "$?"
}


function fetch_updates {
    if [ ! -x "$JOSH" ]; then
        printf " ** fail ($0): JOSH:'$JOSH' isn't accessible\n" >&2
        return 1

    elif [ -z "$JOSH_CACHE_DIR" ]; then
        printf " ** fail ($0): JOSH_CACHE_DIR:'$JOSH_CACHE_DIR' isn't accessible\n" >&2
        return 2
    fi

    local file="$JOSH_CACHE_DIR/last-fetch"
    local last_check="`cat $file 2>/dev/null`"
    [ -z "$last_check" ] && local last_check="0"

    let fetch_every="${JOSH_UPDATES_FETCH_H:-1} * 3600"
    let need_check="$EPOCHSECONDS - $fetch_every > $last_check"

    if [ "$need_check" -eq 0 ]; then
        echo 0
        return 0
    fi

    local last_fetch="`fs_mtime "$JOSH/.git/FETCH_HEAD" 2>/dev/null`"
    let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"

    local cwd="$PWD" && builtin cd "$JOSH"
    local branch="`git_current_branch`"

    if [ -z "$branch" ]; then
        builtin cd "$cwd"
        printf " ** fail ($0): branch '$branch' empty" >&2
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
        async_job updates_fetcher fetch_updates_background
    fi

    [ ! -d "`fs_dirname "$file"`" ] && mkdir -p "`fs_dirname "$file"`"
    echo "$EPOCHSECONDS" > "$file"

    [ -z "$count" ] && echo 0 || echo "$count"
    builtin cd "$cwd"
}


function check_updates {
    if [ ! -x "$JOSH" ]; then
        printf " ** fail ($0): JOSH:'$JOSH' isn't accessible\n" >&2
        return 1

    elif [ -z "$JOSH_CACHE_DIR" ]; then
        printf " ** fail ($0): JOSH_CACHE_DIR:'$JOSH_CACHE_DIR' isn't accessible\n" >&2
        return 1
    fi
    unset JOSH_UPDATES_COUNT

    local updates="`fetch_updates`"
    [ "$?" -gt 0 ] && return 1
    [ "$updates" -eq 0 ] && return 0

    local file="$JOSH_CACHE_DIR/last-update"
    local last_check="`cat $file 2>/dev/null`"
    [ -z "$last_check" ] && local last_check="0"

    let check_every=" ${JOSH_UPDATES_REPORT_D:-1} * 86400"
    let need_check="$EPOCHSECONDS - $check_every > $last_check"
    [ "$need_check" -eq 0 ] && return 0

    local cwd="$PWD" && builtin cd "$JOSH"
    git_repository_clean
    if [ "$?" -gt 0 ]; then
        builtin cd "$cwd"
        return 2
    fi

    local branch="`git_current_branch`"
    if [ "$branch" = "develop" ]; then
        printf " -- info ($0): $updates new commits found, let's go!\n" >&2
        josh_pull "$branch"
        local ret="$?"
        printf " -- info ($0): commits applied, please run: exec zsh\n" >&2
        printf " for partial (fast) update run: josh_update\n" >&2
        printf " for install (full) all updates: josh_upgrade\n" >&2

    elif [ "$branch" = "stable" ]; then
        local last_commit="`git --git-dir="$JOSH/.git" --work-tree="$JOSH/" log -1 --format="%ct"`"
        let wait_stable=" ${JOSH_UPDATES_STABLE_STAY_D:-7} * 86400"
        let need_check="$EPOCHSECONDS - $wait_stable > $last_commit"
        [ "$need_check" -eq 0 ] && return 0
    fi

    JOSH_UPDATES_COUNT="$updates"
    [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"
    echo "$EPOCHSECONDS" > "$file"
    echo "$branch"
}


function motd {
    local branch="`check_updates`"

    if [ -n "$TMUX" ]; then
        return 0

    elif [ -z "$branch" ]; then
        return 0

    elif [ -z "$JOSH_UPDATES_COUNT" ]; then
        return 0

    elif [ "$JOSH_UPDATES_COUNT" -eq 0 ]; then
        return 0

    fi

    local cwd="$PWD" && builtin cd "$JOSH"
    local ctag="`git describe --tags --abbrev=0 2>/dev/null`"
    local ftag="`git --no-pager log --oneline --no-walk --tags="?.?.?" --format="%d" | grep -Po '\d+\.\d+\.\d+' | proximity-sort - | tail -n 1`"
    local last_commit="`git log -1 --format="at %h updated %cr" 2>/dev/null`"
    builtin cd "$cwd"

    if [ "$branch" = 'master' ]; then
        if [ "$ctag" ] && [ ! "$ctag" = "$ftag" ]; then
            echo " + Josh v$ctag (upgrade to v$ftag downloaded), just run: run: josh_update, then: exec zsh"
        fi

    elif [ "$branch" = 'develop' ]; then
        echo " + Josh v$ctag $branch $last_commit."

    else
        echo " + Josh v$ctag $branch $last_commit, found $JOSH_UPDATES_COUNT updates, run: josh_update, then: exec zsh"

    fi
}
