function __pip_completion {
  # pip zsh completion
  local words cword
  read -Ac words
  read -cn cword
  reply=( $( COMP_WORDS="$words[*]" \
             COMP_CWORD=$(( cword-1 )) \
             PIP_AUTO_COMPLETE=1 $words[1] ) )
}
compctl -K __pip_completion pip

# ———

setopt extendedglob nomatch notify
zstyle ':completion:*' completer _expand _complete _oldlist _ignored _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-compctl false

zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z\-}={A-Z\_}' 'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' 'r:|?=** m:{a-z\-}={A-Z\_}'

_comp_options+=(globdots)

autoload -Uz compinit
compinit -u # -u insecure!

# ———

if [ -f "`which -p broot`" ]; then
    eval "$(broot --print-shell-function zsh)"
fi

if [ -f "`which -p pip`" ]; then
    eval "$(pip completion --zsh)"
fi

if [ -f "`which -p starship`" ]; then
    eval "$(starship init zsh)"
fi

if [ -f "`which -p scotty`" ]; then
    eval "$(scotty init zsh)"
fi

if [ -f "`which -p fuck`" ]; then
    eval $(thefuck --alias --enable-experimental-instant-mode)
fi
