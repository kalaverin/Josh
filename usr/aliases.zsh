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
alias -g TO_LINE="awk '{\$1=\$1};1' | sed -z 's:\n: :g' | awk '{\$1=\$1};1'"

alias -g E_INFO="| grep -v '\[INFO\]'"
alias -g E_DEBUG="| grep -v '\[DEBUG\]'"
alias -g E_WARNING="| grep -v '\[WARNING\]'"
alias -g uri="$HTTP_GET"


# ———

# nano: default editor for newbies like me
#
if [ -x "`which nano`" ]; then
    export EDITOR="nano"
fi


# rip: safely and usable rm -rf replace
#
if [ -x "`which rip`" ]; then
    export GRAVEYARD=${GRAVEYARD:-"$HOME/.trash"}
fi


# sccache: very need runtime disk cache for cargo, from cold start have cachehit about 60%+
#
if [ -x "`which sccache`" ] && [ -z "$RUSTC_WRAPPER" ]; then
    export RUSTC_WRAPPER="sccache"
fi


# viu: terminal images previewer in ANSI graphics, used in file previews, etc
#
# if [ -x "`which viu`" ]; then
# fi


# vivid: ls color theme generator
#
if [ -x "`which vivid`" ]; then
    # just run: `vivid themes` or select another one from:
    # ayu jellybeans molokai one-dark one-light snazzy solarized-dark solarized-light
    export LS_COLORS="`vivid generate ${VIVID_THEME:-"molokai"}`"
fi


# just my settings for recursive grep
#
alias ri="`which grep` --line-buffered -rnH --exclude '*.js' --exclude '*.min.css' --exclude '.git/' --exclude 'node_modules/' --exclude 'lib/python*/site-packages/' --exclude '__snapshots__/' --exclude '.eggs/' --exclude '*.pyc' --exclude '*.po' --exclude '*.svg' --color=auto"


# httpie: modern, fast and very usable HTTP client
#
if [ -x "`which http`" ]; then
    # run `http --help` to select theme to HTTPIE_THEME
    HTTPIE_OPTIONS=${HTTPIE_OPTIONS:-"--verify no --default-scheme http --follow --all --format-options json.indent:2 --compress --style ${HTTPIE_THEME:-"gruvbox-dark"}"}
    alias http="http $HTTPIE_OPTIONS"
fi


# ag: silver searcher, ripgrep like golang tools with many settings
#
if [ -x "`which ag`" ]; then
    AG_OPTIONS=${AG_OPTIONS:-"-C1 --noaffinity --path-to-ignore ~/.ignore --stats --smart-case --width 140"}
fi


# ripgrep
#
if [ -x "`which rg`" ]; then
    local ripgrep_fast='--max-columns $COLUMNS --smart-case'
    local ripgrep_fine='--max-columns $COLUMNS --case-sensitive --fixed-strings --word-regexp'
    local ripgrep_interactive="--no-stats --text --context 1 --colors 'match:fg:yellow' --colors 'path:fg:red' --context-separator ''"

    export JOSH_RIPGREP="rg"
    local realpath="`which realpath`"
    export JOSH_RIPGREP_OPTS="--require-git --hidden --max-columns-preview --max-filesize=50K --ignore-file=`$realpath --quiet ~/.gitignore`"

    alias rf="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast"
    alias rfs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast --sort path"
    alias rr="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine"
    alias rrs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine --sort path"
fi


# git-hist: cool tool for fast check git file history, for lamers, of cource
#
if [ -x "`which git-hist`" ]; then
    GIT_HIST_OPTIONS=${GIT_HIST_OPTIONS:-"--beyond-last-line --emphasize-diff --full-hash"}
    alias ghist="git-hist $GIT_HIST_OPTIONS"
fi


# lsd: modern ls for my catalog previews
#
if [ -x "`which lsd`" ]; then
    LSD_OPTIONS=${LSD_OPTIONS:-'--extensionsort --classify --long --versionsort'}
    alias ll="lsd --almost-all $LSD_OPTIONS"
    alias l="lsd --ignore-glob '*.pyc' $LSD_OPTIONS"
fi


# bat: is modern cat with file syntax highlighting
#
if [ -x "`which bat`" ]; then
    # you can select another theme, use fast preview with your favorite source file:
    # bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"

    export PAGER="bat"
    export BAT_STYLE="${BAT_STYLE:-"numbers,changes"}"
    export BAT_THEME="${BAT_THEME:-"gruvbox-dark"}"
fi


# git-delta: beatiful git differ with many settings, fast and cool
#
if [ -x "`which delta`" ]; then
    DELTA_OPTIONS=${DELTA_OPTIONS:-"--commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"}
    export DELTA="delta $DELTA_OPTIONS"
    if [ -x "`which bat`" ]; then
        export DELTA="$DELTA --pager bat"
    fi
fi


# fzf: amazing fast fuzzy search and select tool
#
if [ -x "`which fzf`" ]; then
    export FZF_DEFAULT_OPTS="--ansi --extended"
    export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --color=always --exclude .git/ --exclude \"*.pyc\" --exclude node_modules/"
    export FZF_THEME=${FZF_THEME:-"fg:#ebdbb2,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54"}
fi


# csview: just csview with delimiters
#
if [ -x "`which csview`" ]; then
    alias csv="csview --style Rounded"
    alias tsv="csv --tsv"
    alias ssv="csv --delimiter ';'"
fi


if [ -x "`which docker`" ]; then
    export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
    export BUILDKIT_INLINE_CACHE=${BUILDKIT_INLINE_CACHE:-1}
    export COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-1}
fi

[ -x "`which lolcate`" ]  && alias lc="lolcate"
[ -x "`which micro`" ] && alias mi="micro"
[ -x "`which rsync`" ] && alias cpdir="rsync --archive --links --times"
[ -x "`which rcrawl`" ] && alias dtree="rcrawl -Rs"

# ———


if [ -x "`which tree`" ]; then
    lst() {
        tree -F -f -i | grep -v '[/]$' I $*
    }
fi

if [ -x "`which gpg`" ]; then
    kimport() {
        [ -z "$1" ] && return 1
        gpg --recv-key $1 && gpg --export $1 | apt-key add -
    }
fi

if [ -x "`which wget`" ]; then
    function sget {
        wget --no-check-certificate -O- $* &> /dev/null
    }
    function nget {
        wget --no-check-certificate -O/dev/null $*
    }
fi

if [ -x "`which ssh-agent`" ]; then
    alias ssh-agent="$temp"

    function initalize_agent {
        eval `ssh-agent` && ssh-add
    }
fi


naming_functions=()
if [ -x "`which xkpwgen`" ]; then
    function make_xkpwgen_name() {
        local count=${1:-2}
        local sep=${2:-'.'}
        echo "`xkpwgen -l $count -n 1 -s "$sep"`"
    }
    naming_functions+=(make_xkpwgen_name)
fi

if  [ -x "`which pgen`" ]; then
    function make_pgen_name() {
        local count=${1:-2}
        local sep=${2:-'.'}
        echo "`pgen -n $count -k 1 | sd '( +)' "$sep"`"
    }
    naming_functions+=(make_pgen_name)
fi

if [ -x "`which petname`" ]; then
    function make_petname_name() {
        local count=${1:-2}
        local sep=${2:-'.'}
        echo "`petname -s "$sep" -w $count -a`"
    }
    naming_functions+=(make_petname_name)
fi

local count=${#naming_functions[@]}
if [ "$count" -gt 0 ]; then
    local select=$(printf "%d" $[RANDOM%$count+1])
    if [ "$select" -gt 0 ]; then
        make_human_name="${naming_functions[$select]}"
        function make_human_name() {
            echo "`$make_human_name $*`"
        }
    fi
fi


function mktp {
    mkcd "$(fs_dirname `mktemp -duq`)/pets/`make_human_name`"
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

pathprune
