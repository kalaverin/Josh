alias cp='cp -iR'  # prompt on overwrite and use recurse for directories
alias mv='mv -i'
alias tt='tail --retry --quiet --sleep-interval=0.5 -f -n 50'
alias sudo='sudo -H'  # this is Ubuntu behavior: never send user env to sudo context!
alias svc='sudo service'

# ———

alias -g I='| grep --line-buffered -i'
alias -g E='| grep --line-buffered -iv'
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g TO_LINE="awk '{\$1=\$1};1' | sed -z 's:\n: :g' | awk '{\$1=\$1};1'"

alias -g E_INFO="| grep --line-buffered -v '\[INFO\]'"
alias -g E_DEBUG="| grep --line-buffered -v '\[DEBUG\]'"
alias -g E_WARNING="| grep --line-buffered -v '\[WARNING\]'"
alias -g uri="$HTTP_GET"


# ———

# nano: default editor for newbies like me
#
if [ -x "$commands[nano]" ]; then
    export EDITOR="nano"
fi


# rip: safely and usable rm -rf replace
#
if [ -x "$commands[rip]" ]; then
    export GRAVEYARD=${GRAVEYARD:-"$HOME/.trash"}
fi


# sccache: very need runtime disk cache for cargo, from cold start have cachehit about 60%+
#
if [ -x "$commands[sccache]" ] && [ -z "$RUSTC_WRAPPER" ]; then
    export RUSTC_WRAPPER="sccache"
fi


# viu: terminal images previewer in ANSI graphics, used in file previews, etc
#
# if [ -x "$commands[viu]" ]; then
# fi


# vivid: ls color theme generator
#
if [ -x "$commands[vivid]" ]; then
    # just run: `vivid themes` or select another one from:
    # ayu jellybeans molokai one-dark one-light snazzy solarized-dark solarized-light
    export LS_COLORS="`vivid generate ${VIVID_THEME:-"molokai"}`"
fi


# just my settings for recursive grep
#
alias ri="grep --line-buffered -rnH --exclude '*.js' --exclude '*.min.css' --exclude '.git/' --exclude 'node_modules/' --exclude 'lib/python*/site-packages/' --exclude '__snapshots__/' --exclude '.eggs/' --exclude '*.pyc' --exclude '*.po' --exclude '*.svg' --color=auto"


# httpie: modern, fast and very usable HTTP client
#
if [ -x "$commands[http]" ]; then
    # run `http --help` to select theme to HTTPIE_THEME
    HTTPIE_OPTIONS=${HTTPIE_OPTIONS:-"--verify no --default-scheme http --follow --all --format-options json.indent:2 --compress --style ${HTTPIE_THEME:-"gruvbox-dark"}"}
    alias http="http $HTTPIE_OPTIONS"
fi

if [ -x "$commands[xh]" ]; then
    XH_OPTIONS=${XH_OPTIONS:-"--verify no --default-scheme http --follow --all --style monokai"}
    alias htt="xh $XH_OPTIONS"
fi

# ag: silver searcher, ripgrep like golang tools with many settings
#
if [ -x "$commands[ag]" ]; then
    alias ag="$commands[ag] ${AG_OPTIONS:---context=1 --noaffinity --smart-case --width 140 --path-to-ignore ~/.ignore --path-to-ignore ~/.gitignore}"
fi

# pastel
if [ -x "$commands[pastel]" ]; then
    export PASTEL_COLOR_MODE=8bit
fi

# ripgrep
#
if [ -x "$commands[rg]" ]; then
    local realpath="$commands[realpath]"
    local ripgrep_fast='--max-columns $COLUMNS --smart-case'
    local ripgrep_fine='--max-columns $COLUMNS --case-sensitive --fixed-strings --word-regexp'
    local ripgrep_interactive="--no-stats --text --context 1 --colors 'match:fg:yellow' --colors 'path:fg:red' --context-separator ''"

    export JOSH_RIPGREP="rg"
    export JOSH_RIPGREP_OPTS="--require-git --hidden --max-columns-preview --max-filesize=1M --ignore-file=$($realpath --quiet ~/.gitignore)"

    # if [ -x "$commands[hgrep]" ]; then
    #     function rt {
    #         $(which rg) -nH $* | $(which hgrep) -G -c 2 -C 3 $*
    #     }
    # fi

    alias rr="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast"
    alias rrs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast --sort path"
    alias rf="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine"
    alias rfs="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine --sort path"
fi


# git-hist: cool tool for fast check git file history, for lamers, of cource
#
if [ -x "$commands[git-hist]" ]; then
    GIT_HIST_OPTIONS=${GIT_HIST_OPTIONS:-"--beyond-last-line --emphasize-diff --full-hash"}
    alias ghist="git-hist $GIT_HIST_OPTIONS"
fi


# lsd: modern ls for my catalog previews
#
if [ -x "$commands[lsd]" ]; then
    LSD_OPTIONS=${LSD_OPTIONS:-'--extensionsort --classify --long --versionsort'}
    alias ll="lsd --almost-all $LSD_OPTIONS"
    alias l="lsd --ignore-glob '*.pyc' $LSD_OPTIONS"
fi


# bat: is modern cat with file syntax highlighting
#
if [ -x "$commands[bat]" ]; then
    # you can select another theme, use fast preview with your favorite source file:
    # bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/any/file"

    export PAGER="bat"
    export BAT_STYLE="${BAT_STYLE:-"numbers,changes"}"
    export BAT_THEME="${BAT_THEME:-"gruvbox-dark"}"
fi


# difftascit: beatiful diff wrapper with syntax highlight
#
if [ -x "$commands[difft]" ]; then
    function dift() { difft --color always $* | less }

    export DFT_DISPLAY="${DFT_DISPLAY:-"side-by-side"}"
    export DFT_TAB_WIDTH="${DFT_TAB_WIDTH:-"4"}"
    export DFT_NODE_LIMIT="${DFT_NODE_LIMIT:-"30000"}"
    export DFT_SYNTAX_HIGHLIGHT="${DFT_SYNTAX_HIGHLIGHT:-"on"}"
fi


# git-delta: beatiful git differ with many settings, fast and cool
#
if [ -x "$commands[delta]" ]; then
    DELTA_OPTIONS=${DELTA_OPTIONS:-"--commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-header-decoration-style='' --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate --relative-paths"}
    export DELTA="delta $DELTA_OPTIONS"
    if [ -x "$commands[bat]" ]; then
        export DELTA="$DELTA --pager bat"
    fi
fi


# fzf: amazing fast fuzzy search and select tool
#
if [ -x "$commands[fzf]" ]; then
    export FZF_DEFAULT_OPTS="--ansi --extended"
    export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --color=always --exclude .git/ --exclude \"*.pyc\" --exclude node_modules/"
    export FZF_THEME=${FZF_THEME:-"fg:#ebdbb2,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54"}
fi


# csview: just csview with delimiters
#
if [ -x "$commands[csview]" ]; then
    alias csv="csview --style Rounded"
    alias tsv="csv --tsv"
    alias ssv="csv --delimiter ';'"
fi


if [ -x "$commands[docker]" ]; then
    export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
    export BUILDKIT_INLINE_CACHE=${BUILDKIT_INLINE_CACHE:-1}
    export COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-1}
fi

[ -x "$commands[gfold]" ]   && alias gls="gfold -d classic"
[ -x "$commands[lolcate]" ] && alias lc="lolcate"
[ -x "$commands[micro]" ]   && alias mi="micro"
[ -x "$commands[rcrawl]" ]  && alias dtree="rcrawl -Rs"
[ -x "$commands[rsync]" ]   && alias cpdir="rsync --archive --links --times"

# ———


if [ -x "$commands[tree]" ]; then
    lst() {
        tree -F -f -i | grep -v '[/]$' I $*
    }
fi

if [ -x "$commands[gpg]" ]; then
    kimport() {
        [ -z "$1" ] && return 1
        gpg --recv-key $1 && gpg --export $1 | apt-key add -
    }
fi

if [ -x "$commands[wget]" ]; then
    function sget {
        wget --no-check-certificate -O- $* &> /dev/null
    }
    function nget {
        wget --no-check-certificate -O/dev/null $*
    }
fi

function ssh.agent {
    if [ -x "$commands[ssh-add]" ] && [ -x "$commands[ssh-agent]" ]; then
        eval $(ssh-agent) >/dev/null
    fi
}

if [ -z "$SSH_AUTH_SOCK" ]; then
    ssh.agent
    ssh-add 2>/dev/null
else
    ssh-add 2>/dev/null
    if [ "$?" -eq 2 ]; then
        ssh.agent
        ssh-add 2>/dev/null
    fi
fi


naming_functions=()
if [ -x "$commands[xkpwgen]" ]; then
    function __pwd.func.xkpwgen {
        echo "$(xkpwgen -l ${1:-2} -n 1 -s "${2:-.}")"
    }
    naming_functions+=(__pwd.func.xkpwgen)
fi

if  [ -x "$commands[pgen]" ]; then
    function __pwd.func.pgen {
        echo "$(pgen -n ${1:-2} -k 1 | sd '( +)' "${2:-.}")"
    }
    naming_functions+=(__pwd.func.pgen)
fi

if [ -x "$commands[names]" ]; then
    function __pwd.func.names {
        echo "$(names | sed -z 's:-:.:g')"
    }
    naming_functions+=(__pwd.func.names)
fi

if [ -x "$commands[petname]" ]; then
    function __pwd.func.petname {
        echo "$(petname -s "${2:-.}" -w ${1:-2} -a)"
    }
    naming_functions+=(__pwd.func.petname)
fi

if [ -x "$commands[readable-name-generator]" ]; then
    function __pwd.func.readablenamegenerator {
        echo "$(readable-name-generator -s "${2:-.}")"
    }
    naming_functions+=(__pwd.func.readablenamegenerator)
fi

if [ -x "$commands[easypassword]" ]; then
    function __pwd.func.easypassword {
        echo "$(easypassword "${2:-.}" '' -n ${1:-2})"
    }
    naming_functions+=(__pwd.func.easypassword)
fi

local count=${#naming_functions[@]}
if [ "$count" -gt 0 ]; then
    function get.name {
        let select="($RANDOM % $count) + 1"
        local result="$(${naming_functions[$select]} $*)"
        printf "${result:l}"
    }
fi

function mktp {
    mkcd "$(get_tempdir)/pet/$(get.name)"
}

function shortcut- {
    [ -z "$ZSH" ] || [ -z "$1" ] && return 1

    local dir="$JOSH/bin"

    if [[ "$1" =~ "/" ]]; then
        printf " ** fail ($0): shortcut '$1' couldn't contains slashes\n" >&2
        return 1
    fi

    local src="$dir/$1"

    if [ ! -h "$src" ]; then
        printf " ** fail ($0): shortcut '$src' isn't symbolic link\n" >&2
        return 2
    else

        local dst="$(fs_readlink "$src")"
        unlink "$src"
        local ret="$?"

        if [ "$ret" -eq 0 ]; then
            printf " ++ warn ($0): unlink shortcut '$src' -> '$dst'\n" >&2
        else
            printf " ** fail ($0): unlink shortcut '$src' -> '$dst' failed: $ret\n" >&2
            return "$ret"
        fi
    fi
}

function brew {
    source "$JOSH/lib/brew.sh" && brew.env

    local bin="$(brew.bin 2>/dev/null)"
    if [ ! -x "$bin" ]; then
        brew.init || return 1
    fi

    local bin="$(brew.bin)"
    [ ! -x "$bin" ] && return 2


    if [ "$1" = 'install' ]; then
        run_show "brew.install ${@:2}"

    elif [ "$1" = 'env' ]; then
        brew.env
        export | grep -i BREW

    elif [ "$1" = 'extras' ]; then
        brew.extras

    else
        run_show "$bin $*"
    fi
}

# ———

function fchmod {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find "$2" -type f -not -perm $1 -exec chmod "$1" {} \;
}

function dchmod {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find "$2" -type d -not -perm $1 -exec chmod "$1" {} \;
}

function rchgrp {
    [ -z "$1" ] && [ -z "$2" ] && return 1
    find "$2" -not -group "$1" -exec chgrp "$1" {} \;
}
