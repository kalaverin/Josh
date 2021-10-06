if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi

function tmux_go() {
    if [[ -n "$PS1" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        if [ -z "`tmux_any_session`" ]; then
            tmux new-session -s "${1:-`make_human_name 1`}"
        else
            tmux attach-session -t "${1:-`tmux_matched_detached_session || tmux_detached_session`}"
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
        | tabulate -d ':' -i 1 \
        | head -n 1 \
    )
    [ -z "$result" ] && return 1
    echo "$result"
}

function tmux_detached_session() {
    local result=$(
        tmux list-sessions 2>/dev/null \
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
