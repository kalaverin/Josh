setopt extendedglob notify

zstyle ':completion:*' completer _expand _complete _oldlist _ignored _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-compctl false

zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z\-}={A-Z\_}' 'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' 'r:|?=** m:{a-z\-}={A-Z\_}'
zstyle :plugin:history-search-multi-word reset-prompt-protect 1

_comp_options+=(globdots)


function completition.generate {
    path.rehash
    [ -x "$commands[broot]" ]    && broot --print-shell-function zsh
    [ -x "$commands[fuck]" ]     && thefuck --alias
    [ -x "$commands[pip]" ]      && pip completion --zsh
    [ -x "$commands[scotty]" ]   && scotty init zsh

    local file="$HOME/.zcompdump"
    if [ -f "$file" ]; then
        let need_check="$EPOCHSECONDS - 300 > $(fs.mtime $file 2>/dev/null)"
        [ "$need_check" -eq 0 ] && return
    fi
    compinit
}

eval $(BINARY_SAFE=1 eval.cached "$(fs.lm.many $path)" completition.generate)

[ -x "$commands[starship]" ] && eval $(starship init zsh)

autoload -Uz compinit
