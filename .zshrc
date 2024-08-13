if [ -f "$HOME/.ash/run/init.sh" ]; then
    source "$HOME/.ash/run/init.sh"

elif [ -f "$HOME/.josh/custom/plugins/josh/run/boot.sh" ]; then
    source "$HOME/.josh/custom/plugins/josh/run/boot.sh"
fi


path=(
    $path
    /etc/rc.d
    /usr/local/etc/rc.d
)

SAVEHIST=50000
HISTSIZE=55000

export UPDATE_ZSH_DAYS=7
export ZSH_PLUGINS_ALIAS_TIPS_TEXT=" => "

ZSH_THEME="fishy"
HISTFILE="$HOME/.histfile"
HIST_STAMPS="yyyy-mm-dd"

plugins=(
    autoupdate
    alias-tips
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

# user can configure some variables for configure Josh and other plugins
[ -f ~/.zshrclocal ] && source ~/.zshrclocal

source "$ASH/src/configure.zsh"
source "$ZSH/oh-my-zsh.sh"
source "$ASH/src/loader.zsh"

# user can override anything after load
[ -f ~/.zshrcbinds ] && source ~/.zshrcbinds
