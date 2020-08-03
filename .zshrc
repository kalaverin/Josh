export ZSH=~/.josh
export JOSH=$ZSH/custom/plugins/josh

export BAT_STYLE="full"
export BAT_THEME="Nord" # select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
export EDITOR="nano"

export FZF_DEFAULT_OPTS="--ansi --extended"
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --color=always --exclude .git/ --exclude "*.pyc" --exclude node_modules/'

export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export MM_CHARSET='UTF-8'
export WRKDIRPREFIX="/tmp"

if [ -n "$(uname | grep -i freebsd)" ]; then
    export DELTA="delta --commit-style plain --file-style plain --hunk-style plain --highlight-removed"
else
    export DELTA="delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers --navigate"
fi
# доделать цвета и для номеров строк
#

HTTPIE_THEMES='abap arduino default fruity monokai native perldoc rrt solarized tango trac'

HISTSIZE=100000
SAVEHIST=100000

FORGIT_FZF_DEFAULT_OPTS="
  --exact
  --border
  --cycle
  --reverse
  --height '80%'
"

ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  end-of-line
  vi-forward-char
  vi-end-of-line
  vi-add-eol
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
  forward-char
  forward-word
  emacs-forward-word
  vi-forward-word
  vi-forward-word-end
  vi-forward-blank-word
  vi-forward-blank-word-end
  vi-find-next-char
  vi-find-next-char-skip
)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

BAT_BIN=`which bat`
LISTER_LESS="`which less` -M"
if [ ! -f $BAT_BIN ]; then
  LISTER_FILE="$LISTER_LESS -Nu"
else
  LISTER_FILE="$BAT_BIN --color always --tabs 4 --paging never"
fi

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

EMOJI_CLI_KEYBIND="\eo"
ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets

source "$ZSH/oh-my-zsh.sh"
source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-abbr-path/.abbr_pwd"
source "$ZSH/custom/plugins/zsh-fuzzy-search-and-edit/plugin.zsh"
source "$ZSH/custom/plugins/emoji-cli/emoji-cli.zsh"
source "$ZSH/custom/plugins/zsh-plugin-fzf-finder/fzf-finder.plugin.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting-filetypes/zsh-syntax-highlighting-filetypes.zsh"

zmodload zsh/terminfo
export VIRTUAL_ENV_DISABLE_PROMPT=1

source "$JOSH/contrib/aliases.zsh"
source "$JOSH/contrib/httpclient.zsh"
source "$JOSH/contrib/completion.zsh"
source "$JOSH/contrib/urlencode.zsh"
source "$JOSH/contrib/functions.zsh"
source "$JOSH/contrib/bindings.zsh"

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

local znt_list_instant_select=1

export DOCKER_BUILDKIT=1
export BUILDKIT_INLINE_CACHE=1
export COMPOSE_DOCKER_CLI_BUILD=1

unsetopt correct_all
unsetopt correct

setupsolarized dircolors.256dark

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrclocal ] && source ~/.zshrclocal
[ -f ~/.zshrcbinds ] && source ~/.zshrcbinds
