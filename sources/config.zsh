export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export MM_CHARSET='en_US.UTF-8'

if [ -f "`which -p bat`" ]; then
    export PAGER="bat"
    export BAT_STYLE="full"
    export BAT_THEME="${THEME_BAT:-gruvbox-dark}" # select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
    unset THEME_BAT
fi

if [ -f "`which -p docker`" ]; then
    export DOCKER_BUILDKIT=1
    export BUILDKIT_INLINE_CACHE=1
    export COMPOSE_DOCKER_CLI_BUILD=1
fi

if [ -f "`which -p fzf`" ]; then
    export FZF_DEFAULT_OPTS="--ansi --extended"
    export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --color=always --exclude .git/ --exclude "*.pyc" --exclude node_modules/'
fi

[ -f "`which -p micro`" ] && export EDITOR="micro"
[ -f "`which -p rip`" ] && export GRAVEYARD="$REAL/.trash"
[ -f "`which -p sccache`" ] && export RUSTC_WRAPPER=`which sccache`
[ -f "`which -p vivid`" ] && export LS_COLORS="`vivid generate ${THEME_LS:-solarized-dark}`"

EMOJI_CLI_KEYBIND="\eo"

ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets

ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
    end-of-line
    vi-end-of-line
    vi-add-eol
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
    forward-char
    forward-word
    emacs-forward-word
    vi-forward-char
    vi-forward-blank-word
    vi-forward-blank-word-end
    vi-forward-word
    vi-forward-word-end
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

PAGER_BIN=`which -p $PAGER`
LISTER_LESS="`which -p less` -M"
if [ ! -f $PAGER_BIN ]; then
    LISTER_FILE="$LISTER_LESS -Nu"
else
    LISTER_FILE="$PAGER_BIN --color always --tabs 4 --paging never" # for bat
fi
