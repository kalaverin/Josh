if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi

function tmx() {
    if [[ -n "$PS1" ]] && [[ -n "$SSH_CONNECTION" ]]; then

        if [ -n "$1"  ]; then
            if [ "$1" = 'any' ]; then
                local session="$(
                    tmx_get_matching_detached_session ||
                    tmx_get_detached_session ||
                    tmx_get_any_session)"

            elif [ "$1" = 'last' ]; then
                local session="$(
                    tmx_get_matching_detached_session ||
                    tmx_get_detached_session)"

            elif [ "$1" = 'lost' ]; then
                local session="$(
                    tmx_get_matching_detached_session)"
            else
                local session="$1"
            fi

            if [ -z "$session" ]; then
                return 1

            else
                if [ -n "`tmx_is_session_exists "$session"`" ]; then
                    tmux attach-session -t "$session"
                else
                    tmux new-session -s "$session"
                fi
                return "$?"
            fi

        else
            tmux new-session -s "`tmx_get_matching_detached_session || make_human_name 1`"
        fi
    fi
}

function tmx_is_session_exists() {
    [ -z "$1" ] && return 2
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.33 cat | grep -P "^$1$" | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmx_get_any_session() {
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.33 cat | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmx_get_detached_session() {
    local result=$(
        tmux list-sessions -f "#{?session_attached,,1}" -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.33 cat | tabulate -d ':' -i 1 | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmx_get_matching_detached_session() {
    local maxdiff="${JOSH_TMUX_MAX_DIFF_AUTORETACH:-9}"
    local query='zmodload zsh/mathfunc && echo "$((abs(#{window_width} - $COLUMNS) + abs(#{window_height} - $LINES))) #{session_name}"'

    local result="$(
        tmux list-sessions -f "#{?session_attached,,1}" -F $query 2>/dev/null |
        timeout -s 2 0.33 zsh | sort -Vk 1 | head -n 1 |
        sd '(\d+) (.+)' "echo \"\$((\$1 <= $maxdiff)) \$2\"" | zsh |
        grep -P '^1' | tabulate -i 2
    )"
    [ -z "$result" ] && return 1 || echo "$result"
}

if [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ] && [ -z "$JOSH_TMUX_DISABLE_AUTORETACH" ]; then
    tmx lost
fi
