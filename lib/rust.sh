#!/bin/zsh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$HTTP_GET" ]; then
        source "`dirname $0`/../run/boot.sh"
    fi

    JOSH_CACHE_DIR="$HOME/.cache/josh"
    if [ ! -d "$JOSH_CACHE_DIR" ]; then
        mkdir -p "$JOSH_CACHE_DIR"
        echo " * make Josh cache directory \`$JOSH_CACHE_DIR\`"
    fi

    CARGO_BINARIES="$HOME/.cargo/bin"
    [ ! -d "$CARGO_BINARIES" ] && mkdir -p "$CARGO_BINARIES"

    if [ ! -d "$CARGO_BINARIES" ]; then
        mkdir -p "$CARGO_BINARIES"
        echo " * make Cargo goods directory \`$CARGO_BINARIES\`"
    fi

    if [ -n "$JOSH_DEST" ]; then
        BASE="$JOSH_BASE"
    else
        BASE="$JOSH"
    fi
fi

CARGO_REQ_PACKAGES=(
    bat              # modern replace for cat with syntax highlight
    cargo-update     # packages for auto-update installed crates
    cfonts           # colored terminal text with fonts
    chit             # crates info, just type: chit <any>
    csview           # for commas, tabs, etc
    fd-find          # fd, fast replace for find for humans
    git-delta        # fast replace for git delta with steroids
    git-interactive-rebase-tool
    hgrep            # wonderful grep with syntax highlight
    lsd              # fast ls replacement
    petname          # generate human readable strings
    proximity-sort   # path sorter
    ripgrep          # rg, fast replace for grep -ri for humans
    rm-improved      # rip, powerful rm replacement with trashcan
    runiq            # fast uniq replacement
    scotty           # directory crawling statistics with search
    sd               # fast sed replacement for humans
    starship         # shell prompt
    tabulate         # autodetect columns in stdin and tabulate
    vivid            # ls colors themes selections system
    pastel           # color logging
)
CARGO_REC_PACKAGES=(
    bingrep          # extract and grep strings from binaries
    broot            # console file manager
    bump-bin         # versions with semver specification
    diffsitter       # AST based diff
    dirstat-rs       # ds, du replace, summary tree
    dtool            # code decode swiss knife
    du-dust          # dust, du replace, verbose tree
    dull             # strip any ANSI (color) sequences from pipe
    dupe-krill       # replace similar (by hash) files with hardlinks
    durt             # du replace, just sum
    dusage           # df replace
    easypassword     # password generator
    gfold            # git reps in directory branches status
    gip              # show my ip
    git-bonsai       # full features analyze and remove unnecessary branches
    git-eq           # autocommit all changes to new branch and push it
    git-hist         # git history for selected file
    git-hooks-dispatch
    git-trim         # remove local branches when remote merged
    git-who          # list branches with date, author and merge status
    hexyl            # hex viewer
    ignoreit         # powerful .gitignore for any languages
    jfmt             # minifier
    jira-terminal    # jira client
    jql              # select values by path from JSON input for humans
    jsonfmt          # another JSON minifier
    kalker           # powerful terminal interactive calculator
    krabby           # show pokemon
    lnx              # xargs replacement, pass args from stdio
    loadem           # website load maker
    mdcat            # Markdown files rendered viewer
    miniserve        # directory serving over http
    parallel-sh      # shell commands parallizer
    pgen             # password generator
    procs            # ps aux replacement for humans
    ptit             # print images into terminal
    qrrs             # qr code terminal tool
    quickdash        # hasher
    rcrawl           # very fast file searcher by pattern in directory
    readable-name-generator
    rhit             # very fast nginx log analyzer with graphical stats
    rjo              # JSON generator by key->value
    ruplacer         # refactoring tool, like sed for directory
    ry               # jq for yamls
    sbyte            # hexeditor
    so               # command line TUI full featured stack overflow questions
    trippy           # network diagnosis tool
    tuc              # cut replacer
    viu              # print images into terminal
    xcp              # cp replacement
    xh               # rust httpie replacement
    xkpwgen          # generate human readable strings
    xt               # json, yaml, toml and msgpack converter
    yj               # YAML to JSON converter
    ytop             # htop analogue
)
CARGO_OPT_PACKAGES=(
    b0x
    ch4              # plain dns client, dig like
    difftastic       # diff colored visualizer
    doh-client       # full featured client with caching
    doh-proxy        # doh servier, proxy to plain dns
    dssim            # pictures similarity compare tool
    duf              # miniserver analogue
    feroxbuster      # agressively website dumper
    genact           # console activity generator
    httm             # file versions tool
    https-dns        # simple client
    hyperfine        # time replacement and benchmarking tool
    investments      # stocks tools
    ipgeo            # geoloc by hostname/ip
    just             # command runner like make
    limber           # elasticsearch importer/exporter
    logtail          # graphical tail logs in termial
    lolcate-rs       # blazing fast filesystem database
    mprober          # top like tool
    navi             # local TUI cheatsheets with repositories
    onefetch         # graphical statistics for git repository
    rustscan         # scanner around nmap
    ss-rs            # shadowsocks server and client
    streampager      # less for streams
    tickrs           # realtime ticker
    tidy-viewer      # csv prettry printer
    x8               # websites scan tool
)

CARGO_BIN="$CARGO_BINARIES/cargo"

function cargo_init {
    local cache_exe="$CARGO_BINARIES/sccache"

    if [ ! -x "$CARGO_BIN" ]; then
        export RUSTC_WRAPPER=""
        unset RUSTC_WRAPPER

        url='https://sh.rustup.rs'

        $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME="$HOME/.rustup" CARGO_HOME="`fs_dirname $CARGO_BINARIES`" RUSTUP_INIT_SKIP_PATH_CHECK=yes $SHELL -s - --profile minimal --no-modify-path --quiet -y

        if [ "$?" -gt 0 ] || [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo '$CARGO_BIN' isn't installed"
            return 127
        else
            info $0 "$($CARGO_BIN --version) in '$CARGO_BIN'"
        fi
    fi

    export PATH="$CARGO_BINARIES:$PATH"

    if [ ! -x "$cache_exe" ]; then
        $CARGO_BIN install sccache
        if [ ! -x "$cache_exe" ]; then
            info $0 "sccache '$cache_exe' isn't compiled"
        fi
    fi

    if [ -z "$RUSTC_WRAPPER" ] || [ ! -x "$RUSTC_WRAPPER" ]; then
        if [ -x "$cache_exe" ]; then
            export RUSTC_WRAPPER="$cache_exe"

        elif [ -x "`which sccache`" ]; then
            export RUSTC_WRAPPER="`which sccache`"

        else
            export RUSTC_WRAPPER=""
            unset RUSTC_WRAPPER
            info $0 "sccache doesn't exists"
        fi
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        $CARGO_BIN install cargo-update
        if [ ! -x "$update_exe" ]; then
            info $0 "cargo-update '$update_exe' isn't compiled"
        fi
    fi

    return 0
}

function cargo_deploy {
    cargo_init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        fail $0 "cargo '$CARGO_BIN' isn't found"
        return 1
    fi

    $SHELL -c "$(fs_realpath $CARGO_BINARIES/rustup) update"

    local retval=0
    for pkg in $@; do
        $CARGO_BIN install $pkg
        if [ "$?" -gt 0 ]; then
            local retval=1
        fi
    done
    return "$retval"
}

function cargo_extras {
    cargo_install "$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
    return 0
}

function cargo_all {
    cargo_install "$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES $CARGO_OPT_PACKAGES"
    return 0
}

function cargo_list_installed {
    cargo_init || return "$?"

    if [ ! -x "$CARGO_BIN" ]; then
        fail $0 "cargo exe $CARGO_BIN isn't found!"
        return 1
    fi
    echo "$($CARGO_BIN install --list | egrep '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ')"
}

function cargo_install {
    cargo_init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        fail $0 "cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    if [ -n "$*" ]; then
        local selected="$*"
    else
        local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
    fi

    local installed_regex="($(
        cargo_list_installed | sed -z 's:\n: :g' | \
        sed 's/ *$//' | sd '\b +\b' '|'))"

    local missing_packages="$(
        echo "$selected" | sd '\s+' '\n' | grep -Pv "$installed_regex" | \
        sed -z 's:\n: :g' | sed 's/ *$//')"

    [ -z "$missing_packages" ] && return 0

    local autoinstall="$(
        echo "$*" | sd '\s+' '\n' | grep -Pv "$installed_regex" | \
        sed -z 's:\n: :g' | sed 's/ *$//')"

    if [ -n "$autoinstall" ]; then
        local packages="$autoinstall"
    else
        local packages="$($SHELL -c "
            echo "$missing_packages" \
            | sd ' +' '\n' \
            | proximity-sort - \
            | $FZF \
                --multi \
                --nth=2 \
                --tiebreak='index' \
                --layout=reverse-list \
                --prompt='install > ' \
                --preview='chit {1}' \
                --preview-window="left:`get_preview_width`:noborder" \
            | $UNIQUE_SORT | $LINES_TO_LINE
        ")"
    fi

    if [ -n "$packages" ]; then
        run_show "$CARGO_BIN install $packages"
    fi
}

function cargo_uninstall {
    cargo_init || return $?

    if [ ! -x "$CARGO_BIN" ]; then
        fail $0 "cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local required_regex="($(echo "$CARGO_REQ_PACKAGES" | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'))"

    if [ -n "$*" ]; then
        local selected="$*"
    else
        local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
    fi

    local installed_regex="($(
        cargo_list_installed | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'))"

    local installed_packages="$(
        echo "$selected" | sd '\s+' '\n' | \
        grep -P "$installed_regex" | \
        grep -Pv "$required_regex" | \
        sed -z 's:\n: :g' | sed 's/ *$//')"

    [ -z "$installed_packages" ] && return 0

    local autoremove="$(
        echo "$*" | sd '\s+' '\n' | \
        grep -P "$installed_regex" | \
        grep -Pv "$required_regex" | \
        sed -z 's:\n: :g' | sed 's/ *$//')"

    if [ -n "$autoremove" ]; then
        local packages="$autoremove"
    else
        local packages="$($SHELL -c "
            echo "$installed_packages" \
            | sd ' +' '\n' \
            | proximity-sort - \
            | $FZF \
                --multi \
                --nth=2 \
                --tiebreak='index' \
                --layout=reverse-list \
                --prompt='uninstall > ' \
                --preview='chit {1}' \
                --preview-window="left:`get_preview_width`:noborder" \
            | $UNIQUE_SORT | $LINES_TO_LINE
        ")"
    fi

    if [ -n "$packages" ]; then
        run_show "$CARGO_BIN uninstall $packages"
    fi
}

function cargo_recompile {
    local packages="$(cargo_list_installed | sed -z 's:\n: :g' | sed 's/ *$//')"
    if [ -n "$packages" ]; then
        $SHELL -c "$CARGO_BIN install --force $packages"
    fi
}

function cargo_update {
    cargo_init || return "$?"

    if [ ! -x "$CARGO_BIN" ]; then
        fail $0 "cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        fail $0 "cargo-update exe $update_exe isn't found!"
        return 1
    fi

    $SHELL -c "$(fs_realpath $CARGO_BINARIES/rustup) update"
    $CARGO_BIN install-update --all
    return "$?"
}

function rust_env {
    cargo_init
}
