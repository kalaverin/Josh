export EDITOR="nano"
export BAT_STYLE="full"
export BAT_THEME="Nord" # select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"

export FZF_DEFAULT_OPTS="--ansi --extended"
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --color=always --exclude .git/ --exclude "*.pyc" --exclude node_modules/'

export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export MM_CHARSET='en_US.UTF-8'

export DOCKER_BUILDKIT=1
export BUILDKIT_INLINE_CACHE=1
export COMPOSE_DOCKER_CLI_BUILD=1

EMOJI_CLI_KEYBIND="\eo"
ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets

HTTPIE_THEMES='abap arduino default fruity monokai native perldoc rrt solarized tango trac'

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

FORGIT_FZF_DEFAULT_OPTS="
  --exact
  --border
  --cycle
  --reverse
  --height '80%'
"

BAT_BIN=`which bat`
LISTER_LESS="`which less` -M"
if [ ! -f $BAT_BIN ]; then
  LISTER_FILE="$LISTER_LESS -Nu"
else
  LISTER_FILE="$BAT_BIN --color always --tabs 4 --paging never"
fi
