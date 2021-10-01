zmodload zsh/datetime


function is_workhours() {
    local head="${JOSH_WORKHOUR_START:-10}"
    local tail="${JOSH_WORKHOUR_END:-18}"

    local current_hour="`builtin strftime '%H' $EPOCHSECONDS`"
    if [ "$current_hour" -ge "$head" ] && [ "$current_hour" -lt "$tail" ]; then
        return 0
    fi
    return 1
}


function fetch_updates() {
    if [ -z "$JOSH" ]; then
        echo " - $0 warning: JOSH:\`$JOSH\`" >&2
        return 1

    elif [ -z "$JOSH_CACHE_DIR" ]; then
        echo " - $0 warning: JOSH_CACHE_DIR:\`$JOSH_CACHE_DIR\`" >&2
        return 1
    fi

    local cwd="$PWD" && builtin cd "$JOSH"
    local branch="`git_current_branch`"
    if [ -z "$branch" ]; then
        builtin cd "$cwd"
        echo " - $0 warning: JOSH branch isn't retrieved" >&2
        return 1
    fi

    local hash="`git_current_hash`"
    if [ -z "$hash" ]; then
        builtin cd "$cwd"
        echo " - $0 warning: JOSH hash isn't retrieved" >&2
        return 1
    fi

    local file="$JOSH_CACHE_DIR/last-fetch"
    local data="`cat $file 2>/dev/null`"
    local fetch_every="$(( ${JOSH_FETCH_UPDATES_HOUR:-1} * 3600 ))"

    if [ -z "$data" ] || [ "$(( $EPOCHSECONDS - $data ))" -gt "$fetch_every" ]; then
        [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"
        echo "$EPOCHSECONDS" > "$file"
        git fetch origin "$branch" 2>/dev/null
    fi

    local count="$(
        git --git-dir="$JOSH/.git" --work-tree="$JOSH/" \
        rev-list --left-right --count $hash...$branch | tabulate -i 2
    )"

    [ -z "$count" ] && echo 0 || echo "$count"
    builtin cd "$cwd"
}


function check_updates() {
    if [ -z "$JOSH" ]; then
        echo " - $0 warning: JOSH:\`$JOSH\`"
        return 1

    elif [ -z "$JOSH_CACHE_DIR" ]; then
        echo " - $0 warning: JOSH_CACHE_DIR:\`$JOSH_CACHE_DIR\`"
        return 1
    fi
    local updates="`fetch_updates`"
    [ "$?" -gt 0 ] && return 1
    [ "$updates" -eq 0 ] && return 0

    local file="$JOSH_CACHE_DIR/last-update"
    local data="`cat $file 2>/dev/null`"
    local check_every="$(( ${JOSH_CHECK_UPDATES_DAYS:-1} * 86400 ))"

    if [ -z "$data" ] || [ "$(( $EPOCHSECONDS - $data ))" -gt "$check_every" ]; then
        [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"
        echo "$EPOCHSECONDS" > "$file"

        local cwd="$PWD" && builtin cd "$JOSH"
        local branch="`git_current_branch`"
        builtin cd "$cwd"

        if [ "$branch" = "develop" ]; then
            echo " + $0: $updates updates ready to install, let's go"
            josh_pull "$branch"

        elif [ "$branch" = "stable" ]; then
            local last_commit="`git --git-dir="$JOSH/.git" --work-tree="$JOSH/" log -1 --format="%ct"`"

            if [ "$(( $EPOCHSECONDS - $last_commit ))" -gt "$check_every" ]; then
                JOSH_UPDATES_FOUND="$updates"
            fi
        fi
    fi
}

is_workhours && true || check_updates

unset check_updates
unset fetch_updates
