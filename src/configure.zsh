# first, set locale
#

ASH_DEFAULT_LOCALE="${DEFAULT_LOCALE:-"en_US.UTF-8"}"

export LANG="${LANG:-"$ASH_DEFAULT_LOCALE"}"
export LANGUAGE="${LANGUAGE:-"$ASH_DEFAULT_LOCALE"}"
export LC_ALL="${LC_ALL:-"$ASH_DEFAULT_LOCALE"}"

if [ "$ASH_OS" = "BSD" ]; then
    export MM_CHARSET="${MM_CHARSET:-"$ASH_DEFAULT_LOCALE"}"
fi

# init optional environment

source "$ASH/lib/python.sh" && \
py.home >/dev/null && \
pip.exe >/dev/null

source "$ASH/lib/go.sh" && go.init
source "$ASH/lib/rust.sh" && cargo.init

if [ ! -f "$HOME/.config/starship.toml" ]; then
    export STARSHIP_CONFIG="$ASH/usr/share/starship.toml"
fi

# ASH_PY_ENVS_ROOT
# directory for permanent virtualenvs maded by virtualenv_create
#
ASH_PY_ENVS_ROOT="${ASH_PY_ENVS_ROOT:-"$HOME/envs"}"

# ASH_WORKHOUR_START, ASH_WORKHOUR_END
# work hours for ignore annoying nehavior
#
ASH_WORKHOUR_START=${ASH_WORKHOUR_START:-10} # from 10, -> 10:00
ASH_WORKHOUR_END=${ASH_WORKHOUR_END:-18}     # till 18, <- 17:59

# ASH_UPDATES_FETCH_H
# fetch commits from remote every hour (except work hours)
# it's background async task to except annoying
#
ASH_UPDATES_FETCH_H=${ASH_UPDATES_FETCH_H:-2}

# ASH_UPDATES_REPORT_D
# how frequenlty report and suggest install updates
# but for develop — this is autopull period
#
ASH_UPDATES_REPORT_D=${ASH_UPDATES_REPORT_D:-1}

# ASH_UPDATES_STABLE_STAY_D
# just for stable, delay after last commit with N days
# to display message about commits count
#
ASH_UPDATES_STABLE_STAY_D=${ASH_UPDATES_STABLE_STAY_D:-7}

# ASH_TMUX_DISABLE_AUTORETACH
# Josh scan sessions and connect to detached matching with current terminal size
# bu default - enabled
#
#ASH_TMUX_AUTORETACH_DISABLE=1

#ASH_TMUX_AUTORETACH_MAX_DIFF
# maximum summary diff with width and height
#
ASH_TMUX_AUTORETACH_MAX_DIFF=9

#ASH_TMUX_SPACES_FILL_DISABLE
# disable default: clear terminal and move prompth to bottom place
#
# ASH_TMUX_SPACES_FILL_DISABLE=1

#ASH_TMUX_MOTD_DISABLE
# disable default: show random pokemon and Darks Souls phrase
#
# ASH_TMUX_MOTD_DISABLE=1

#ASH_SSH_AGENT_AUTOSTART_DISABLE
# disable default: show random pokemon and Darks Souls phrase
#
# ASH_SSH_AGENT_AUTOSTART_DISABLE=1

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

export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_"

FZF_DEFAULT_OPTS="
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
