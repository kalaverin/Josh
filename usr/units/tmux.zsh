if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi


function tml {
    echo "--- Current: ${COLUMNS}x${LINES}"
    tmux list-sessions -F ' #{?session_attached,+,-} #{window_height}x#{window_width} #{session_name}'
}

function tmx {
    if [ -n "$1"  ]; then
        if [ "$1" = 'any' ]; then
            local session="$(
                __tmux.get_matching_detached_session ||
                __tmux.get_detached_session ||
                __tmux.get_any_session)"

        elif [ "$1" = 'last' ]; then
            local session="$(
                __tmux.get_matching_detached_session ||
                __tmux.get_detached_session)"

        elif [ "$1" = 'lost' ]; then
            local session="$(
                __tmux.get_matching_detached_session)"
        else
            local session="$1"
        fi

        if [ -z "$session" ]; then
            return 1

        else
            if [ -n "`__tmux.is_session_exists "$session"`" ]; then
                tmux attach-session -t "$session"
            else
                tmux new-session -s "$session"
            fi
            return "$?"
        fi

    else
        tmx lost || tmux new-session -s "$(get.name 1)"
    fi
}

function __tmux.is_session_exists {
    [ -z "$1" ] && return 2
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | grep -P "^$1$" | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function __tmux.get_any_session {
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function __tmux.get_detached_session {
    local result=$(
        tmux list-sessions -f "#{?session_attached,,1}" -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | tabulate -d ':' -i 1 | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function __tmux.get_matching_detached_session {
    local maxdiff="${JOSH_TMUX_AUTORETACH_MAX_DIFF:-9}"
    local query='zmodload zsh/mathfunc && echo "$((abs(#{window_width} - $COLUMNS) + abs(#{window_height} - $LINES))) #{session_name}"'

    local result="$(
        tmux list-sessions -f "#{?session_attached,0,1}" -F $query 2>/dev/null |
        timeout -s 2 0.25 $SHELL | sort -Vk 1 |
        sd '(\d+) (.+)' "echo \"\$((\$1 <= $maxdiff)) \$2\"" | $SHELL |
        grep -P '^1' | head -n 1 | tabulate -i 2
    )"
    [ -z "$result" ] && return 1 || echo "$result"
}

function cls {
    clear
    if [ -z "$JOSH_TMUX_MOTD_DISABLE" ]; then
        if [ -x "$commands[krabby]" ]; then
            krabby random | sed 1d | head -n -1
        fi
        if [ -x "$commands[dsmsg]" ]; then
            let color="31 + ($RANDOM % 7)"
            printf "\033[2;${color}m -- $(dsmsg --ds1 --ds2 --ds3)\033[0m\n"
        fi
    fi
}

if [ -z "$JOSH_TMUX_AUTORETACH_DISABLE" ] && [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
    tmx lost

elif [ -z "$JOSH_TMUX_SPACES_FILL_DISABLE" ] && [ -n "$PS1" ] && [ -n "$TMUX" ]; then
    local branch="$(ash.branch)"
    if [ "$branch" = "master" ] || [ "$branch" = "stable" ]; then
        cls
    fi
fi
