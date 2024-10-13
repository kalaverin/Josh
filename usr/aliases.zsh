alias cp='cp -iR'  # prompt on overwrite and use recurse for directories
alias mv='mv -i'
alias tt='tail --retry --sleep-interval=0.1 --follow --lines=100'
alias ttt='tail --retry --sleep-interval=0.1 --follow --lines=5000'
alias sudo='sudo -H --preserve-env="PATH,HOME"'  # this is Ubuntu behavior: never send user env to sudo context!
alias svc='sudo service'
alias fd='fd --no-ignore-vcs --hidden --exclude .git/'

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

# gh: github copilot aliases
#
if [ -x "$commands[gh]" ]; then
    function how {
        run.show "gh copilot suggest --target shell $*"
    }
    function how.git {
        run.show "gh copilot suggest --target git $*"
    }
fi

# sccache: very need runtime disk cache for cargo, from cold start have cachehit about 60%+
#
if [ -x "$commands[sccache]" ]; then
    [ -z "$CCACHE" ] && export CCACHE="sccache"
    [ -z "$CC_WRAPPER" ] && export CC_WRAPPER="sccache"
    [ -z "$FC_WRAPPER" ] && export FC_WRAPPER="sccache"
    [ -z "$CXX_WRAPPER" ] && export CXX_WRAPPER="sccache"
    [ -z "$RUSTC_WRAPPER" ] && export RUSTC_WRAPPER="sccache"

    [ -z "$CC" ] && [ -x "$commands[gcc]" ] && export CC="sccache gcc"
    [ -z "$CXX" ] && [ -x "$commands[g++]" ] && export CXX="sccache g++"
    [ -z "$FC" ] && [ -x "$commands[gfortran]" ] && export CXX="sccache gfortran"
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
    HTTPIE_OPTIONS=${HTTPIE_OPTIONS:-"--verify no --default-scheme http --follow --all --format-options json.indent:2 --style ${HTTPIE_THEME:-"gruvbox-dark"}"}
    alias http="http $HTTPIE_OPTIONS"
fi

if [ -x "$commands[xh]" ]; then
    XH_OPTIONS=${XH_OPTIONS:-"--verify no --default-scheme http --follow --all --style monokai"}
    alias www="xh $XH_OPTIONS"
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

    export ASH_RIPGREP="rg"
    export ASH_RIPGREP_OPTS="--require-git --hidden --max-columns-preview --max-filesize=1M --ignore-file=$($realpath --quiet ~/.gitignore)"

    # if [ -x "$commands[hgrep]" ]; then
    #     function rt {
    #         $(which rg) -nH $* | $(which hgrep) -G -c 2 -C 3 $*
    #     }
    # fi
    alias rr="$ASH_RIPGREP $ASH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast"
    alias rrs="$ASH_RIPGREP $ASH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fast --sort path"
    alias rf="$ASH_RIPGREP $ASH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine"
    alias rfs="$ASH_RIPGREP $ASH_RIPGREP_OPTS $ripgrep_interactive $ripgrep_fine --sort path"
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
    if [ -z "$LSD_OPTIONS" ]; then
        LSD_OPTIONS='--classify --long'
        if [ -f "$HOME/.config/lsd/config.yaml" ]; then
            LSD_OPTIONS="--config-file \"$HOME/.config/lsd/config.yaml\" $LSD_OPTIONS"
        fi
    fi
    alias l="lsd $LSD_OPTIONS"
    alias ll="lsd --almost-all $LSD_OPTIONS"
else
    alias l="ls -l"
    alias ll="ls -la"
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


# tabulate is rust tools for easy split stdout to columns
#
if [ ! -x "$commands[tabulate]" ]; then
    term $0 "tabulate tool is required"
else
    export TABULATE="$commands[tabulate]"
    alias tabulate="$commands[tabulate] 2>/dev/null"
fi


# git-delta: beatiful git differ with many settings, fast and cool
#
if [ -x "$commands[delta]" ]; then
    export DELTA_OPTIONS="--commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-header-decoration-style='' --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-right-format='{np:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --merge-conflict-ours-diff-header-decoration-style='' --merge-conflict-ours-diff-header-style='dim cyan' --merge-conflict-theirs-diff-header-decoration-style='' --merge-conflict-theirs-diff-header-style='dim cyan' --line-numbers --navigate --diff-so-fancy --line-fill-method='spaces'"

    let width="$(misc.preview.width)"
    if [ "$width" -ge 158 ]; then
        export DELTA_OPTIONS="$DELTA_OPTIONS --side-by-side"
    fi
    let width="$width + 4"
    export DELTA_OPTIONS="$DELTA_OPTIONS --width=$width"
    export DELTA="delta $DELTA_OPTIONS"
    if [ -x "$commands[bat]" ]; then
        export DELTA="$DELTA --pager bat"
    fi
    export DELTA="$DELTA 2>/dev/null"
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

# xc: markdown executor, orginally for buildtools, now — for custom aliases
#
if [ -x "$commands[xc]" ]; then
    function it {
        book="${PROJECT_EXECUTE:-$ASH/playbook.md}"
        part="${PROJECT_SECTION:-Playbook}"

        xc -file "$book" -heading "$part"
    }
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

if [ -x "$commands[git-summary]" ] && [ "$(misc.cpu.count)" -gt 0 ]; then
    alias gs="git-summary --hidden --parallel $(misc.cpu.count)"
fi


# ———


if [ -x "$commands[tree]" ]; then
    function lst {
        if [ -n "$*" ]; then
            tree -F -f -i | grep -v '[/]$' I $*
        else
            tree -F -f -i | grep -v '[/]$'
        fi
    }
fi

if [ -x "$commands[gpg]" ]; then
    function kimport {
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

if [ -x "$commands[direnv]" ]; then
    eval "$(direnv hook zsh)"
fi

function ssh.agent {
    if [ -x "$commands[ssh-add]" ] && [ -x "$commands[ssh-agent]" ]; then
        eval $(ssh-agent) >/dev/null
    fi
}

if [ "$ASH_SSH_AGENT_AUTOSTART" -gt 0 ]; then
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

if [ -x "$commands[petname]" ]; then
    function __pwd.func.petname {
        echo "$(petname -s "${2:-.}" -w ${1:-2} -a)"
    }
    naming_functions+=(__pwd.func.petname)
fi

if [ -x "$commands[easypassword]" ]; then
    function __pwd.func.easypassword {
        echo "$(easypassword '.' '.' -n ${1:-2} | sd '\.' "${2:-.}" | sd '\.$' '')"
    }
    naming_functions+=(__pwd.func.easypassword)
fi

if [ -x "$commands[names]" ]; then
    function __pwd.func.names {
        echo "$(names | sd '-' "${2:-.}")"
    }
    naming_functions+=(__pwd.func.names)
fi

if [ -x "$commands[readable-name-generator]" ]; then
    function __pwd.func.readablenamegenerator {
        echo "$(readable-name-generator -s "${2:-.}")"
    }
    naming_functions+=(__pwd.func.readablenamegenerator)
fi

local count=${#naming_functions[@]}
if [ "$count" -eq 0 ]; then
    function get.name {
        warn "$0" 'cannod detect any generation function'
        return 1
    }

else
    function get.name {
        local amount select
        if [ -z "$1" ] || [ "$1" -eq 2 ]; then
            let amount="$count"
        else
            let amount="$count - 2"
        fi

        let amount="$count"
        if [ -n "$1" ] && [ ! "$1" -eq 2 ]; then
            if [ -x "$commands[names]" ]; then
                let amount="$count - 1"
            fi
            if [ -x "$commands[readable-name-generator]" ]; then
                let amount="$count - 1"
            fi
        fi

        let select="($RANDOM % $amount) + 1"
        local result="$(${naming_functions[$select]} $*)"
        printf "${result:l}"
    }
fi

function mktp {
    mkcd "$(temp.dir)/pet/$(get.name)"
}

function brew {
    source "$ASH/lib/brew.sh" && brew.env

    local bin="$(brew.bin 2>/dev/null)"
    if [ ! -x "$bin" ]; then
        brew.init || return 1
    fi

    local bin="$(brew.bin)"
    [ ! -x "$bin" ] && return 2


    if [ "$1" = 'install' ]; then
        run.show "brew.install ${@:2}"

    elif [ "$1" = 'env' ]; then
        brew.env
        export | grep -i BREW

    elif [ "$1" = 'extras' ]; then
        brew.extras

    else
        run.show "$bin $*"
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

function super {
    if [ -x $commands[supervisord] ]; then

        if [ -f "supervisord.pid" ] && [ -S "supervisord.sock" ]; then
            pid=$(cat supervisord.pid)
            if pgrep -F supervisord.pid >/dev/null && [ -S "supervisord.sock" ]; then
                [ -x $commands[supervisord] ] && supervisorctl
                return 0
            fi
        fi
        supervisord --silent --configuration supervisord.conf
        [ -x $commands[supervisord] ] && supervisorctl
    fi
}
