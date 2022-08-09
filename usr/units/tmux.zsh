if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
fi


function tml {
    echo "   ${LINES}x${COLUMNS} current"
    tmux list-sessions -F ' #{?session_attached,+,-} #{window_height}x#{window_width} #{session_name}' | sort
}

function tmx {
    if [ -n "$1"  ]; then
        if [ "$1" = 'any' ]; then
            local session="$(tmux.matching || tmux.detached || tmux.first)"

        elif [ "$1" = 'last' ]; then
            local session="$(tmux.matching || tmux.detached)"

        elif [ "$1" = 'lost' ]; then
            local session="$(tmux.matching)"
        else
            local session="$1"
        fi

        if [ -z "$session" ]; then
            return 1

        else
            if [ -n "$(tmux.exists "$session")" ]; then
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

function tmux.exists {
    [ -z "$1" ] && return 2
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | grep -P "^$1$" | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmux.first {
    local result=$(
        tmux list-sessions -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmux.detached {
    local result=$(
        tmux list-sessions -f "#{?session_attached,,1}" -F '#{session_name}' 2>/dev/null |
        timeout -s 2 0.25 cat | tabulate -d ':' -i 1 | head -n 1
    )
    [ -z "$result" ] && return 1 || echo "$result"
}

function tmux.matching {
    local result
    local maxdiff="${ASH_TMUX_AUTORETACH_MAX_DIFF:-9}"

    result="$(
        eval.run "tmux list-sessions -f \"#{?session_attached,,1}\" -F 'echo \"\$((abs(#{window_width} - \$COLUMNS) + abs(#{window_height} - \$LINES))) #{session_name}\"' 2>/dev/null"
    )" || return "$?"
    [ -z "$result" ] && return 1


    result="$(
        eval.run "$result" | sort -Vk 1 |
        sd '(\d+) (.+)' "echo \"\$((\$1 <= $maxdiff)) \$2\""
    )" || return "$?"
    [ -z "$result" ] && return 1

    result="$(
        eval.run "$result" | grep -P '^1' | head -n 1 | tabulate -i 2
    )"
    [ -z "$result" ] && return 1 || echo "$result"
}


function tmx.autoload {
    local binaries=(
        grep
        head
        sd
        sed
        sort
        tabulate
        tmux
    )

    if local missing="$(fs.lookup.missing "$binaries")" && [ -n "$missing" ]; then
        fail $0 "missing binaries: $missing; just run 'ash.extras' and try again after"
    fi

    if [ -z "$ASH_TMUX_AUTORETACH_DISABLE" ] && [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
        tmx lost

    elif [ -z "$ASH_TMUX_SPACES_FILL_DISABLE" ] && [ -n "$PS1" ] && [ -n "$TMUX" ]; then
        local branch="$(ash.branch)"
        if [ "$branch" = "master" ] || [ "$branch" = "stable" ]; then
            if [ "$DO_NOT_CLEAR" -eq 1 ]; then
                cls
            else
                echo "lol > $DO_NOT_CLEAR <" >&2
            fi
        fi
    fi
}

tmx.autoload
