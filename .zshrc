if [ ! "$JOSH" ]; then
    source "$HOME/.josh/custom/plugins/josh/run/init.sh"
fi

path=(
    $HOME/.local/bin
    $HOME/bin
    $ZSH/custom/bin
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

SAVEHIST=20000
HISTSIZE=25000

# select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
# THEME_BAT="gruvbox-dark"

# color theme for ls, just run: vivid themes
# ayu jellybeans molokai one-dark one-light snazzy solarized-dark solarized-light
# THEME_LS="solarized-dark"

# http --help to select another ont
# THEME_HTTPIE="paraiso-dark"

# if `starship` disabled, use this theme:
# af-magic blinks dpoggi fishy jreese michelebologna
# ZSH_THEME="josh"

export UPDATE_ZSH_DAYS=30

HISTFILE="$HOME/.histfile"
HIST_STAMPS="yyyy-mm-dd"


plugins=(
    # autoupdate   # autoupdate Josh # TODO: temporary disable
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

# user can configure some variables, e.g. THEME_BAT, THEME_FZF
[ -f ~/.zshrclocal ] && source ~/.zshrclocal

source "$JOSH/src/configure.zsh"
source "$ZSH/oh-my-zsh.sh"
source "$JOSH/src/loader.zsh"

# user can override anything after load all
[ -f ~/.zshrcbinds ] && source ~/.zshrcbinds
