# first, set locale
#

JOSH_DEFAULT_LOCALE="${DEFAULT_LOCALE:-"en_US.UTF-8"}"

export LANG="${LANG:-"$JOSH_DEFAULT_LOCALE"}"
export LANGUAGE="${LANGUAGE:-"$JOSH_DEFAULT_LOCALE"}"
export LC_ALL="${LC_ALL:-"$JOSH_DEFAULT_LOCALE"}"

if [ "$JOSH_OS" = "BSD" ]; then
    export MM_CHARSET="${MM_CHARSET:-"$JOSH_DEFAULT_LOCALE"}"
fi

# init optional environment

source "$JOSH/lib/python.sh" && python.env
source "$JOSH/lib/rust.sh" && rust_env

path_prune

if [ ! -f "$HOME/.config/starship.toml" ]; then
    export STARSHIP_CONFIG="$JOSH/usr/share/starship.toml"
fi

# JOSH_PY_ENVS_ROOT
# directory for permanent virtualenvs maded by virtualenv_create
#
JOSH_PY_ENVS_ROOT="${JOSH_PY_ENVS_ROOT:-"$HOME/envs"}"

# JOSH_WORKHOUR_START, JOSH_WORKHOUR_END
# work hours for ignore annoying nehavior
#
JOSH_WORKHOUR_START=${JOSH_WORKHOUR_START:-10} # from 10, -> 10:00
JOSH_WORKHOUR_END=${JOSH_WORKHOUR_END:-18}     # till 18, <- 17:59

# JOSH_UPDATES_FETCH_H
# fetch commits from remote every hour (except work hours)
# it's background async task to except annoying
#
JOSH_UPDATES_FETCH_H=${JOSH_UPDATES_FETCH_H:-2}

# JOSH_UPDATES_REPORT_D
# how frequenlty report and suggest install updates
# but for develop — this is autopull period
#
JOSH_UPDATES_REPORT_D=${JOSH_UPDATES_REPORT_D:-1}

# JOSH_UPDATES_STABLE_STAY_D
# just for stable, delay after last commit with N days
# to display message about commits count
#
JOSH_UPDATES_STABLE_STAY_D=${JOSH_UPDATES_STABLE_STAY_D:-7}

# JOSH_TMUX_DISABLE_AUTORETACH
# Josh scan sessions and connect to detached matching with current terminal size
# bu default - enabled
#
#JOSH_TMUX_AUTORETACH_DISABLE=1

#JOSH_TMUX_AUTORETACH_MAX_DIFF
# maximum summary diff with width and height
#
JOSH_TMUX_AUTORETACH_MAX_DIFF=9

#JOSH_TMUX_SPACES_FILL_DISABLE
# disable default: clear terminal and move prompth to bottom place
#
# JOSH_TMUX_SPACES_FILL_DISABLE=1

#JOSH_TMUX_MOTD_DISABLE
# disable default: show random pokemon and Darks Souls phrase
#
# JOSH_TMUX_MOTD_DISABLE=1
# JOSH_TMUX_MOTD_DISABLE=1

THEFUCK_EXCLUDE_RULES="fix_file"

# zsh-autosuggestions

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
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=25
# ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c80,)"


FORGIT_FZF_DEFAULT_OPTS="
    --exact
    --border
    --cycle
    --reverse
    --height '80%'
"
if [ -n "$PAGER" ] && [ -x "$(which $PAGER)" ]; then
    PAGER_BIN="$(which $PAGER)"
fi

LISTER_LESS="$(which less) -M"
if [ ! -x "$PAGER_BIN" ]; then
    LISTER_FILE="$LISTER_LESS -Nu"
else
    LISTER_FILE="$PAGER_BIN --color always --tabs 4 --paging never" # for bat
fi
