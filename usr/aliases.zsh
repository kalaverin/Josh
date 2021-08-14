alias cp='cp -iR'
alias ln='ln'
alias mv='mv'
alias ps='ps'
alias rm='rm'
alias tt='tail -f -n 100'
alias svc='service'
# alias pipdeptree='python -m pipdeptree'

alias ri="$JOSH_GREP -rnH --exclude '*.js' --exclude '*.min.css' --exclude '.git/' --exclude 'node_modules/' --exclude 'lib/python*/site-packages/' --exclude '__snapshots__/' --exclude '.eggs/' --exclude '*.pyc' --exclude '*.po' --exclude '*.svg' --color=auto"

# ———

alias -g I='| grep -i'
alias -g E='| grep -iv'
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g GL="awk '{\$1=\$1};1' | $JOSH_SED -z 's:\n: :g' | awk '{\$1=\$1};1'"

alias -g E_INFO="| grep -v '\[INFO\]'"
alias -g E_DEBUG="| grep -v '\[DEBUG\]'"
alias -g E_WARNING="| grep -v '\[WARNING\]'"
alias -g uri="$HTTP_GET"

# ———

[ -f "`which -p $JOSH_DELTA`" ] && alias delta="$JOSH_DELTA"
[ -f "`which -p $JOSH_GREP`" ] && alias grep="$JOSH_GREP --line-buffered"
[ -f "`which -p $JOSH_HTTP`" ] && alias http="$JOSH_HTTP --verify no --default-scheme http --follow --all --format-options json.indent:2 --compress --style ${THEME_HTTPIE:-gruvbox-dark}"
[ -f "`which -p $JOSH_REALPATH`" ] && alias realpath="$JOSH_REALPATH"
[ -f "`which -p $JOSH_SED`" ] && alias sed="$JOSH_SED"

[ -f "`which -p ag`" ] && alias ag='ag -C1 --noaffinity --path-to-ignore ~/.ignore --stats --smart-case --width 140'
[ -f "`which -p bat`" ] && alias aa='bat'
[ -f "`which -p git-hist`" ] && alias ghist='git-hist --beyond-last-line --emphasize-diff --full-hash'
[ -f "`which -p lolcate`" ] && alias lc='lolcate'
[ -f "`which -p lsd`" ] && alias ll='lsd -laAF --icon-theme unicode'
[ -f "`which -p micro`" ] && alias mi='micro'
[ -f "`which -p rsync`" ] && alias cpdir='rsync --archive --links --times'

# ———

if [ -f "`which -p csview`" ]; then
    alias csv="csview --style Rounded"
    alias tsv="csv --tsv"
    alias ssv="csv --delimiter ';'"
fi
if [ -f "`which -p exa`" ]; then
    # --git-ignore is bugged
    alias l="exa -lFag --color=always --git --octal-permissions --group-directories-first"
    alias lt="l --sort time"
fi
if [ -f "`which -p rg`" ]; then
    local ripgrep_fast='--max-columns $COLUMNS --smart-case'
    local ripgrep_fine='--max-columns $COLUMNS --case-sensitive --fixed-strings --word-regexp'
    local ripgrep_interactive="--no-stats --text --context 1 --colors 'match:fg:yellow' --colors 'path:fg:red' --context-separator ''"

    export JOSH_RIPGREP="`which -p rg`"
    export JOSH_RIPGREP_OPTS="--require-git --hidden --max-columns-preview --max-filesize=50K --ignore-file=`$JOSH_REALPATH --quiet ~/.gitignore`"

    alias rf="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast"
    alias rfs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast --sort path"
    alias rr="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine"
    alias rrs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine --sort path"
fi

if [ -f "`which -p tree`" ]; then
    lst() {
        tree -F -f -i | grep -v '[/]$' I $*
    }
fi
if [ -f "`which -p gpg`" ]; then
    kimport() {
        gpg --recv-key $1 && gpg --export $1 | apt-key add -
    }
fi
if [ -f "`which -p wget`" ]; then
    function sget {
        wget --no-check-certificate -O- $* &> /dev/null
    }
    function nget {
        wget --no-check-certificate -O/dev/null $*
    }
fi
if [ -f "`which -p ssg-agent`" ]; then
    function agent {
        eval `ssh-agent` && ssh-add
    }
fi
if [ -f "`which -p petname`" ]; then
    function mktp {
        local tempdir="$(dirname `mktemp -duq`)/pet/`petname -s . -w 3 -a`"
        mkdir -p "$tempdir" && cd "$tempdir"
    }
fi

# ———

function mkcd {
    mkdir "$*" && cd "$*"
}

function run_show() {
    local cmd="$*"
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>&2
}

function run_silent() {
    local cmd="$*"
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>/dev/null 2>/dev/null
}

function run_hide() {
    local cmd="$*"
    eval ${cmd} 1>/dev/null 2>/dev/null
}

# ———

fchmod() {
    find $2 -type f -not -perm $1 -exec chmod $1 {} \;
}

dchmod() {
    find $2 -type d -not -perm $1 -exec chmod $1 {} \;
}

rchgrp() {
    find $2 ( -not -group $1 ) -print -exec chgrp $1 {} ;
}

last-modified() {
    local args="$*"
    if [ ! "$args" ]; then
        local args="."
    fi
    find $args -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1
}

check() {
    ri $@ && rcrawl $@
}
