setopt append_history
setopt extended_history
setopt hist_reduce_blanks
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_verify
setopt inc_append_history
unsetopt sharehistory

unsetopt beep
unsetopt correct
unsetopt correct_all
unsetopt interactive_comments

zmodload zsh/terminfo


WORDCHARS='_'

ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor regexp)

typeset -A ZSH_HIGHLIGHT_PATTERNS
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf' 'fg=white,bold,bg=red')

typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('\bsu\b' fg=white,bg=red,bold)
ZSH_HIGHLIGHT_REGEXP+=('\bsudo\b' fg=white,bg=red,bold)

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]="fg=yellow"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=white"
ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]="fg=red"
