if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi

function tmux_go() {
    if [[ -n "$PS1" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        local session="${1:-`tmux_matched_detached_session`}"

        if [ "`tmux_matched_detached_session`" ]; then
            tmux attach-session -t "$session"

        elif [ -n "$1" ] && [ -n "`tmux_session_exists "$1"`" ]; then
            tmux attach-session -t "$1"

        else
            tmux new-session -s "${1:-`make_human_name 1`}"
        fi
    fi
}

function tmux_go_match() {
    local session="`tmux_matched_detached_session`"
    if [ -n "$session" ]; then
        tmux attach-session -t "$session"
    else
        return "$?"
    fi
}

function tmux_go_any() {
    local session="`tmux_any_session || tmux_detached_session`"
    if [ -n "$session" ]; then
        tmux_go "$session"
    else
        return "$?"
    fi
}

function tmux_any_session() {
    local result=$(
        tmux list-sessions 2>/dev/null \
        | timeout -s 2 0.33 cat \
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

function tmux_session_exists() {
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

function tmux_detached_session() {
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

function tmux_matched_detached_session() {
    let lines="$LINES -1"
    local screen_size="[${COLUMNS}x${lines}]"
    local result=$(
        tmux list-sessions 2>/dev/null \
        | timeout -s 2 0.33 cat \
        | grep -F "$screen_size" \
        | grep -v "(attached)" \
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

if [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ] && [ -z "$JOSH_TMUX_DISABLE_AUTOREATTACH" ]; then
    tmux_go_match
fi

alias tmx='tmux_go'
