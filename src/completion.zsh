zmodload zsh/datetime

setopt extendedglob notify

zstyle ':completion:*' completer _expand _complete _oldlist _ignored _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-compctl false

zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z\-}={A-Z\_}' 'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' 'r:|?=** m:{a-z\-}={A-Z\_}'
zstyle :plugin:history-search-multi-word reset-prompt-protect 1

_comp_options+=(globdots)

[ -x "`lookup scotty`" ] && eval "$(scotty init zsh)"
[ -x "`lookup fuck`" ] && eval $(thefuck --alias)
[ -x "`lookup starship`" ] && eval "$(starship init zsh)"


function completition_expired() {
    if [ "$SHLVL" -gt 1 ]; then
        echo 0
    else
        local file="$HOME/.zcompdump"
        if [ -f "$file" ]; then
            let need_check="$EPOCHSECONDS - 7200 > `fstatm $file 2>/dev/null`"
            if [ "$need_check" -eq 0 ]; then
                echo 0
                return
            fi
        fi
        echo 1
    fi
}


if [ "`completition_expired`" -gt 0 ]; then
    [ -x "`lookup broot`" ] && eval "$(broot --print-shell-function zsh)"
    [ -x "`lookup pip`" ] && eval "$(pip completion --zsh)"

    autoload -Uz compinit
    compinit -u # -u insecure!
fi

function path_last_modified() {
    local unified_path="$(
        echo "$PATH" | sd ':' '\n' \
        | runiq - | xargs -n 1 realpath 2>/dev/null \
        | sd '\n' ':' | sd '(^:|:$)' '' \
    )"
    [ "$?" = 0 ] && [ "$unified_path " ] && export PATH="$unified_path"

    for subdir in $(echo "$PATH" | sd ':' '\n'); do
        echo "`fstatm "$subdir" 2>/dev/null || echo 0` $subdir"
    done
    # path_last_modified | grep -Pv '^0' | sort -n | tail -n 1 | tabulate -i 1
}
