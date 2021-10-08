[ -x "`lookup broot`" ] && eval "$(broot --print-shell-function zsh)"
[ -x "`lookup pip`" ] && eval "$(pip completion --zsh)"
[ -x "`lookup scotty`" ] && eval "$(scotty init zsh)"
[ -x "`lookup fuck`" ] && eval $(thefuck --alias)
[ -x "`lookup starship`" ] && eval "$(starship init zsh)"
