source "$JOSH/lib/python.sh" && python_env
source "$JOSH/lib/rust.sh" && rust_env

export LANG="${LANG:-"en_US.UTF-8"}"
export LANGUAGE="${LANGUAGE:-"en_US:en"}"
export LC_ALL="${LC_ALL:-"en_US.UTF-8"}"
if [ "$JOSH_OS" = "BSD" ]; then
    export MM_CHARSET="${MM_CHARSET:-"en_US.UTF-8"}"
fi

local unified_path="$(echo "$PATH" | sd ':' '\n' | runiq - | xargs -n 1 realpath 2>/dev/null | sd '\n' ':' | sd '(^:|:$)' '')"
[ "$?" = 0 ] && [ "$unified_path " ] && export PATH="$unified_path"

[ -x "`lookup bat`" ] && export JOSH_BAT="`lookup bat`" || true
[ -x "`lookup delta`" ] && export JOSH_DELTA="`lookup delta`" || true
[ -x "`lookup http`" ] && export JOSH_HTTP="`lookup http`" || true
[ -x "`lookup viu`" ] && export JOSH_VIU="`lookup viu`" || true

if [ -x "$JOSH_BAT" ]; then
    export PAGER="$JOSH_BAT"
    export BAT_STYLE="numbers,changes"
    export BAT_THEME="${THEME_BAT:-gruvbox-dark}" # select: bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
    unset THEME_BAT
fi

if [ -x "$JOSH_DELTA" ]; then
    export DELTA="$JOSH_DELTA --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"
    if [ "$JOSH_BAT" ]; then
        export DELTA="$DELTA --pager $JOSH_BAT"
    fi
fi

if [ -x "`lookup docker`" ]; then
    export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
    export BUILDKIT_INLINE_CACHE=${BUILDKIT_INLINE_CACHE:-1}
    export COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-1}
fi

if [ -x "`lookup fzf`" ]; then
    export FZF_DEFAULT_OPTS="--ansi --extended"
    export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --color=always --exclude .git/ --exclude "*.pyc" --exclude node_modules/'
    export FZF_THEME="fg:#ebdbb2,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54"
    export FZF_THEME=${THEME_FZF:-$FZF_THEME}
    unset THEME_FZF
fi

[ -x "`lookup micro`" ] && export EDITOR="`lookup micro`"
[ -x "`lookup rip`" ] && export GRAVEYARD=${GRAVEYARD:-"$HOME/.trash"}
[ -x "`lookup sccache`" ] && export RUSTC_WRAPPER="`lookup sccache`"
[ -x "`lookup vivid`" ] && export LS_COLORS="`vivid generate ${THEME_LS:-solarized-dark}`"

export THEFUCK_EXCLUDE_RULES="fix_file"

EMOJI_CLI_KEYBIND="\eo"

ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets

# zsh-autosuggestions

WORDCHARS='_'
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
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=10
# ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c80,)"


FORGIT_FZF_DEFAULT_OPTS="
    --exact
    --border
    --cycle
    --reverse
    --height '80%'
"

if [ -n "$PAGER" ] && [ -x "`lookup $PAGER`" ]; then
    PAGER_BIN=`lookup $PAGER`
fi

LISTER_LESS="`lookup less` -M"
if [ ! -x "$PAGER_BIN" ]; then
    LISTER_FILE="$LISTER_LESS -Nu"
else
    LISTER_FILE="$PAGER_BIN --color always --tabs 4 --paging never" # for bat
fi

export JOSH_VENVS_DIR="${JOSH_VENVS_DIR:-"$HOME/envs"}"

# JOSH_WORKHOUR_START=10
# JOSH_WORKHOUR_END=18

# JOSH_FETCH_UPDATES_HOUR=12
# JOSH_CHECK_UPDATES_DAYS=3
