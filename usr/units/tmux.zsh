zmodload zsh/mathfunc

if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi

function tmx() {
    if [[ -n "$PS1" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        local session="${1:-`tmx_get_matching_detached_session`}"

        if [ -z "$1" ] && [ "`tmx_get_matching_detached_session`" ]; then
            tmux attach-session -t "$session"

        elif [ -n "$1" ] && [ -n "`tmx_is_session_exists "$1"`" ]; then
            tmux attach-session -t "$1"

        else
            tmux new-session -s "${1:-`make_human_name 1`}"
        fi
    fi
}

function tmx_detached() {
    local session="`tmx_get_detached_session`"
    if [ -n "$session" ]; then
        tmux attach-session -t "$session"
    else
        return "$?"
    fi
}

function tmx_matching() {
    local session="`tmx_get_matching_detached_session`"
    if [ -n "$session" ]; then
        tmux attach-session -t "$session"
    else
        return "$?"
    fi
}

function tmx_existing() {
    local session="`tmx_get_matching_detached_session || tmx_get_detached_session || tmx_get_any_session`"
    if [ -n "$session" ]; then
        tmx "$session"
    else
        return "$?"
    fi
}

function tmx_get_any_session() {
    local result=$(
        tmux list-sessions 2>/dev/null \
        | timeout -s 2 0.33 cat \
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

function tmx_is_session_exists() {
    [ -z "$1" ] && return 1
    local result=$(
        tmux list-sessions 2>/dev/null \
        | timeout -s 2 0.33 cat \
        | grep -P "^$1:" \
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 2
    echo "$result"
}

function tmx_get_detached_session() {
    local result=$(
        tmux list-sessions 2>/dev/null \
        | timeout -s 2 0.33 cat \
        | grep -v "(attached)" \
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

function tmx_get_matching_detached_session() {
    local maxdiff="${JOSH_TMUX_MAX_DIFF_AUTORETACH:-9}"
    local result=$(
        tmux list-sessions 2>/dev/null | \
        timeout -s 2 0.33 cat | \
        grep -Fv '(attached)' | \
        sd '^(.+?):.+\[(\d+)x(\d+)\](.*)' "zmodload zsh/mathfunc && echo \"\$(( abs(\$2 - $COLUMNS) + abs(\$3 - $LINES + 1) <= $maxdiff )):\$1:\$4\"" | \
        zsh | sort -Vk 1 | \
        grep -Pv '^0:' | tabulate -d ':' -i 2 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

if [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ] && [ -z "$JOSH_TMUX_DISABLE_AUTORETACH" ]; then
    tmx_matching
fi
