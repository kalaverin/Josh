zmodload zsh/datetime


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

    elif [ "$branch" = "master" ]; then
        builtin cd "$cwd"
        echo "0"
        return 0
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

function is_workhours() {
    local head="${JOSH_WORKHOUR_START:-10}"
    local tail="${JOSH_WORKHOUR_END:-18}"

    local current_hour="`builtin strftime '%H' $EPOCHSECONDS`"
    if [ "$current_hour" -ge "$head" ] && [ "$current_hour" -lt "$tail" ]; then
        return 0
    fi
    return 1
}

function check_updates() {
    if [ -z "$JOSH" ]; then
        echo " - $0 warning: JOSH:\`$JOSH\`"
        return 1

    elif [ -z "$JOSH_CACHE_DIR" ]; then
        echo " - $0 warning: JOSH_CACHE_DIR:\`$JOSH_CACHE_DIR\`"
        return 1
    fi

    local last_commit="`git --git-dir="$JOSH/.git" --work-tree="$JOSH/" log -1 --format="%ct"`"
    local day_commit="$(( $last_commit ))"
    local day_current="$(( $EPOCHSECONDS ))"

    local check_every="$(( ${JOSH_CHECK_UPDATES_DAYS:-1} * 86400 ))"

    local cwd="$PWD" && builtin cd "$JOSH"
    local branch="`git_current_branch`"
    if [ -z "$branch" ]; then
        builtin cd "$cwd"
        echo " - $0 warning: JOSH branch isn't retrieved" >&2
        return 1
    fi
    builtin cd "$cwd"

    if [ "$(( $day_current - $day_commit ))" -gt "$check_every" ]; then
        local updates="`fetch_updates`"
        [ "$?" -gt 0 ] && return 1
        [ "$updates" -eq 0 ] && return 0

        local file="$JOSH_CACHE_DIR/last-update"
        local data="`cat $file 2>/dev/null`"

        if [ -z "$data" ] || [ "$(( $EPOCHSECONDS - $data ))" -gt "$check_every" ]; then
            [ ! -d "$JOSH_CACHE_DIR" ] && mkdir -p "$JOSH_CACHE_DIR"
            echo "$EPOCHSECONDS" > "$file"

            if [ "$branch" = "develop" ]; then
                echo " + $0 for \`$branch\` autoupdates enabled, $updates updates ready"
                josh_pull "$branch"

            elif  [ "$branch" = "stable" ]; then

                JOSH_UPDATES_FOUND="$updates"
            elif
        fi
    fi
}

is_workhours && true || check_updates
