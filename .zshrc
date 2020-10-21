export ZSH=~/.josh
export JOSH=$ZSH/custom/plugins/josh

source "$JOSH/sources/compat.zsh"

HISTSIZE=100000
SAVEHIST=100000

path=(
  ~/.cargo/bin
  ~/.local/bin
  /bin
  /sbin
  /usr/bin
  /usr/sbin
  /usr/local/bin
  /usr/local/sbin
  /usr/local/etc/rc.d
  /etc/rc.d
  ~/bin
  $ZSH/custom/bin
  $ZSH/custom/plugins/diff-so-fancy
  $path
)

# af-magic blinks dpoggi fishy jreese michelebologna
ZSH_THEME="josh"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=60

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HISTFILE="$HOME/.histfile"
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

export ZSH_AUTOSUGGEST_USE_ASYNC=1
# export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20


# # Treat the '!' character specially during expansion.
# BANG_HIST="false"
# # Write the history file in the ":start:elapsed;command" format.
# EXTENDED_HISTORY="false"
# # Write to the history file immediately, not when the shell exits.
INC_APPEND_HISTORY="true"
# # Share history between all sessions.
SHARE_HISTORY="true"
# # Don't record an entry that was just recorded again.
# HIST_IGNORE_DUPS="false"
# # Do not display a line previously found.
# HIST_FIND_NO_DUPS="false"
# # Don't execute immediately upon history expansion.
# HIST_VERIFY="false"
# # Beep when accessing nonexistent history.
# HIST_BEEP="false"
# Expire duplicate entries first when trimming history.
HIST_EXPIRE_DUPS_FIRST="true"
# Delete old recorded entry if new entry is a duplicate.
HIST_IGNORE_ALL_DUPS="true"
# Don't record an entry starting with a space.
HIST_IGNORE_SPACE="true"
# Don't write duplicate entries in the history file.
HIST_SAVE_NO_DUPS="true"
# Remove superfluous blanks before recording entry.
HIST_REDUCE_BLANKS="true"

ZSH_DISABLE_COMPFIX="true"

plugins=(
  # fast-syntax-highlighting # syntax hihgligher must before history
  alias-tips
  autoupdate
  colored-man-pages
  dircycle # for fast move thru directories with alt-up/down
  docker
  fancy-ctrl-z
  forgit
  git
  gitfast
  history
  history-search-multi-word
  history-substring-search
  httpie
  k
  mysql-colorize
  redis-cli
  safe-paste
  supervisor
  wd
  zsh-256color
  zsh-autopair # for autopair brackets, quoters, etc
  zsh-autosuggestions  # need fix right arrow autoaccept
  zsh-dircolors-solarized
  # zsh-navigation-tools # history-search-multi-word and history-substring-search
  zsh-syntax-highlighting
)

fpath=($ZSH/custom/plugins/anyframe $fpath)
autoload -Uz anyframe-init
anyframe-init
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

zstyle ":anyframe:selector:" use fzf

source "$JOSH/sources/config.zsh"
source "$ZSH/oh-my-zsh.sh"
source "$JOSH/sources/loader.zsh"

zmodload zsh/terminfo
setopt append_history
setopt extended_history
setopt hist_reduce_blanks
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_verify
setopt inc_append_history
setopt share_history
setopt IGNORE_EOF
unsetopt beep

setopt correctall extendedglob nomatch notify
zstyle ':completion:*' completer _expand _complete _oldlist _ignored _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-compctl false
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select

# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
zstyle ':completion:*' matcher-list '' 'm:{a-z\-}={A-Z\_}' 'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' 'r:|?=** m:{a-z\-}={A-Z\_}'

_comp_options+=(globdots)

autoload -Uz compinit
compinit -u # -u insecure!

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrclocal ] && source ~/.zshrclocal
[ -f ~/.zshrcbinds ] && source ~/.zshrcbinds

export VIRTUAL_ENV_DISABLE_PROMPT=1
