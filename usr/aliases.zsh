alias cp='cp -iR'  # prompt on overwrite and use recurse for directories
alias mv='mv -i'
alias tt='tail -f -n 100'
alias svc='service'
alias sudo='sudo -H'  # this is Ubuntu behavior: never do not translate user env to sudo context!

# ———

alias -g I='| grep -i'
alias -g E='| grep -iv'
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g TO_LINE="awk '{\$1=\$1};1' | $JOSH_SED -z 's:\n: :g' | awk '{\$1=\$1};1'"

alias -g E_INFO="| grep -v '\[INFO\]'"
alias -g E_DEBUG="| grep -v '\[DEBUG\]'"
alias -g E_WARNING="| grep -v '\[WARNING\]'"
alias -g uri="$HTTP_GET"

# ———


# nano: default editor for newbies like me
#
local temp="`lookup nano`"
if [ -x "$temp" ]; then
    alias nano="$temp"
    export EDITOR="$temp"
fi


# rip: safely and usable rm -rf replace
#
local temp="`lookup rip`"
if [ -x "$temp" ]; then
    alias rip="$temp"
    export GRAVEYARD=${GRAVEYARD:-"$HOME/.trash"}
fi


# sccache: very need runtime disk cache for cargo, from cold start have cachehit about 60%+
#
local temp="`lookup sccache`"
if [ -x "$temp" ] && [ -z "$RUSTC_WRAPPER" ]; then
    alias sccache="$temp"
    export RUSTC_WRAPPER="$temp"
fi


# viu: terminal images previewer in ANSI graphics, used in file previews, etc
#
local temp="`lookup viu`"
if [ -x "$temp" ]; then
    alias viu="$temp"
    export JOSH_VIU="$temp"
fi


# vivid: ls color theme generator
#
if [ -x "`lookup vivid`" ] && [ -z "$LS_COLORS" ]; then
    # just run: `vivid themes` or select another one from:
    # ayu jellybeans molokai one-dark one-light snazzy solarized-dark solarized-light
    export LS_COLORS="`vivid generate ${VIVID_THEME:-"solarized-dark"}`"
fi


# just my settings for recursive grep
#
if [ -z "$GREP_RECURSIVE_OPTIONS" ]; then
    GREP_RECURSIVE_OPTIONS="-rnH --exclude '*.js' --exclude '*.min.css' --exclude '.git/' --exclude 'node_modules/' --exclude 'lib/python*/site-packages/' --exclude '__snapshots__/' --exclude '.eggs/' --exclude '*.pyc' --exclude '*.po' --exclude '*.svg' --color=auto"
fi
if [ -x "$JOSH_GREP" ]; then
    alias grep="$JOSH_GREP --line-buffered"
    alias ri="$JOSH_GREP $GREP_RECURSIVE_OPTIONS"
fi


# httpie: modern, fast and very usable HTTP client
#
local temp="`lookup http`"
if [ -x "$temp" ]; then
    # run `http --help` to select theme to HTTPIE_THEME
    HTTPIE_OPTIONS=${HTTPIE_OPTIONS:-"--verify no --default-scheme http --follow --all --format-options json.indent:2 --compress --style ${HTTPIE_THEME:-"gruvbox-dark"}"}

    export JOSH_HTTP="$temp"
    alias http="$temp $HTTPIE_OPTIONS"
fi


# ag: silver searcher, ripgrep like golang tools with many settings
#
local temp="`lookup ag`"
if [ -x "$temp" ]; then
    alias ag="$temp"
    AG_OPTIONS=${AG_OPTIONS:-"-C1 --noaffinity --path-to-ignore ~/.ignore --stats --smart-case --width 140"}
fi


# ripgrep
#
local temp="`lookup rg`"
if [ -x "$temp" ]; then
    local ripgrep_fast='--max-columns $COLUMNS --smart-case'
    local ripgrep_fine='--max-columns $COLUMNS --case-sensitive --fixed-strings --word-regexp'
    local ripgrep_interactive="--no-stats --text --context 1 --colors 'match:fg:yellow' --colors 'path:fg:red' --context-separator ''"

    alias rg="$temp"
    export JOSH_RIPGREP="$temp"
    export JOSH_RIPGREP_OPTS="--require-git --hidden --max-columns-preview --max-filesize=50K --ignore-file=`$JOSH_REALPATH --quiet ~/.gitignore`"

    alias rf="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast"
    alias rfs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast --sort path"
    alias rr="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine"
    alias rrs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine --sort path"
fi


# git-hist: cool tool for fast check git file history, for lamers, of cource
#
local temp="`lookup git-hist`"
if [ -x "$temp" ]; then
    GIT_HIST_OPTIONS=${GIT_HIST_OPTIONS:-"--beyond-last-line --emphasize-diff --full-hash"}
    alias git-hist="$temp"
    alias ghist="$temp $GIT_HIST_OPTIONS"
fi


# lsd: modern ls for my catalog previews
#
local temp="`lookup lsd`"
if [ -x "$temp" ]; then
    LSD_OPTIONS=${LSD_OPTIONS:-"-laAF --icon-theme unicode"}
    alias lsd="$temp"
    alias ll="$temp $LSD_OPTIONS"
fi


# bat: is modern cat with file syntax highlighting
#
local temp="`lookup bat`"
if [ -x "$temp" ]; then
    # you can select another theme, use fast preview with your favorite source file:
    # bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"
    export BAT_STYLE="${BAT_STYLE:-"numbers,changes"}"
    export BAT_THEME="${BAT_THEME:-"gruvbox-dark"}"

    alias bat="$temp"
    export PAGER="$temp"
    export JOSH_BAT="$temp"
fi


# git-delta: beatiful git differ with many settings, fast and cool
#
local temp="`lookup delta`"
if [ -x "$temp" ]; then
    alias delta="$temp"
    export JOSH_DELTA="$temp"
    export DELTA="$temp --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"
    if [ -x "$JOSH_BAT" ]; then
        export DELTA="$DELTA --pager $JOSH_BAT"
    fi
fi


# fzf: amazing fast fuzzy search and select tool
#
local temp="`lookup fzf`"
if [ -x "$temp" ]; then
    alias fzf="$temp"
    export FZF_DEFAULT_OPTS="--ansi --extended"
    export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --color=always --exclude .git/ --exclude "*.pyc" --exclude node_modules/'
    export FZF_THEME=${FZF_THEME:-"fg:#ebdbb2,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54"}
fi


# csview: just csview with delimiters
#
local temp="`lookup csview`"
if [ -x "$temp" ]; then
    alias csview="$temp"
    alias csv="$temp --style Rounded"
    alias tsv="csv --tsv"
    alias ssv="csv --delimiter ';'"
fi


# exa: my ls replacement
#
local temp="`lookup exa`"
if [ -x "$temp" ]; then
    alias exa="$temp"
    # --git-ignore is bugged
    export EXA_OPTIONS="${EXA_OPTIONS:-"-lFg --color=always --git --octal-permissions --group-directories-first"}"
    alias l="$temp $EXA_OPTIONS --ignore-glob '*.py?'"
    alias la="$temp -a $EXA_OPTIONS"
    alias lt="l --sort time"
fi


if [ -x "`lookup docker`" ]; then
    export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
    export BUILDKIT_INLINE_CACHE=${BUILDKIT_INLINE_CACHE:-1}
    export COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-1}
fi

[ -x "`lookup lolcate`" ]  && alias lc="lolcate"
[ -x "`lookup micro`" ] && alias mi="micro"
[ -x "`lookup rsync`" ] && alias cpdir="rsync --archive --links --times"


# ———


local temp="`lookup tree`"
if [ -x "$temp" ]; then
    alias tree="$temp"

    lst() {
        tree -F -f -i | grep -v '[/]$' I $*
    }
fi

local temp="`lookup gpg`"
if [ -x "$temp" ]; then
    alias gpg="$temp"

    kimport() {
        [ -z "$1" ] && return 1
        gpg --recv-key $1 && gpg --export $1 | apt-key add -
    }
fi

local temp="`lookup wget`"
if [ -x "$temp" ]; then
    alias wget="$temp"

    function sget {
        wget --no-check-certificate -O- $* &> /dev/null
    }
    function nget {
        wget --no-check-certificate -O/dev/null $*
    }
fi

local temp="`lookup ssh-agent`"
if [ -x "$temp" ]; then
    alias ssh-agent="$temp"

    function initalize_agent {
        eval `ssh-agent` && ssh-add
    }
fi

local temp="`lookup petname`"
if [ -x "$temp" ]; then
    alias petname="$temp"

    function generate_three_words() {
        echo "`petname -s . -w 3 -a`"
    }

    function mktp {
        mkcd "$(dirname `mktemp -duq`)/pet/`generate_three_words`"
    }
fi

# ———

function mkcd {
    [ -z "$1" ] && return 1
    mkdir "$*" && cd "$*"
}

function run_show() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>&2
}

function run_silent() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>/dev/null 2>/dev/null
}

function run_hide() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    eval ${cmd} 1>/dev/null 2>/dev/null
}

# ———

fchmod() {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find $2 -type f -not -perm $1 -exec chmod $1 {} \;
}

dchmod() {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find $2 -type d -not -perm $1 -exec chmod $1 {} \;
}

rchgrp() {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find $2 ( -not -group $1 ) -print -exec chgrp $1 {} ;
}

last_modified() {
    local args="$*"
    if [ -z "$args" ]; then
        local args="."
    fi
    find $args -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1
}


WORDCHARS='_'

ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor line root regexp)

typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('\bsu\b' fg=white,bg=red,bold)
ZSH_HIGHLIGHT_REGEXP+=('\bsudo\b' fg=white,bg=red,bold)

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]="fg=yellow"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=white"
ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]="fg=red"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]="fg=red"
