if [ ! "$JOSH" ]; then
    . "$(sh -c "dirname `realpath ~/.zshrc`")/install/init.sh"
fi

path=(
    ~/.cargo/bin
    $ZSH/custom/bin
    ~/.local/bin
    $REAL/bin
    /usr/local/bin
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/sbin
    /usr/local/etc/rc.d
    /etc/rc.d
    $path
)
source "$JOSH/sources/compat.zsh"

HISTSIZE=100000
SAVEHIST=100000

# select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
# THEME_BAT="gruvbox-dark"

# color theme for ls, just run: vivid themes
# ayu jellybeans molokai one-dark one-light snazzy solarized-dark solarized-light
# THEME_LS="solarized-dark"

# http --help to select another ont
# THEME_HTTPIE="paraiso-dark"


# af-magic blinks dpoggi fishy jreese michelebologna
# ZSH_THEME="josh"

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

# Treat the '!' character specially during expansion.
# BANG_HIST="false"

# Write the history file in the ":start:elapsed;command" format.
# EXTENDED_HISTORY="false"

# Write to the history file immediately, not when the shell exits.
INC_APPEND_HISTORY="true"

# Share history between all sessions.
SHARE_HISTORY="true"
# Don't record an entry that was just recorded again.
# HIST_IGNORE_DUPS="false"

# Do not display a line previously found.
# HIST_FIND_NO_DUPS="false"

# Don't execute immediately upon history expansion.
# HIST_VERIFY="false"

# Beep when accessing nonexistent history.
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
    autoupdate   # autoupdate Josh
    colored-man-pages
    dircycle     # for fast move thru directories with alt-up/down
    docker       # suggestions
    fancy-ctrl-z # ctrl-z to switch active process to background and vice-versa
    forgit
    git
    gitfast
    history
    history-search-multi-word
    history-substring-search
    httpie              # suggestions
    redis-cli           # suggestions
    supervisor          # suggestions
    wd                  # fast bookmarked directory switcher
    zsh-256color        # force 8-bit colors
    zsh-autopair        # for autopair brackets, quoters, etc
    zsh-autosuggestions # live suggestions
    zsh-syntax-highlighting
)

fpath=($ZSH/custom/plugins/anyframe $fpath)
autoload -Uz anyframe-init
anyframe-init

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":anyframe:selector:" use fzf

[ -f ~/.zshrclocal ] && source ~/.zshrclocal

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
zstyle ':completion:*' matcher-list '' 'm:{a-z\-}={A-Z\_}' 'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' 'r:|?=** m:{a-z\-}={A-Z\_}'

_comp_options+=(globdots)

autoload -Uz compinit
compinit -u # -u insecure!

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrcbinds ] && source ~/.zshrcbinds
