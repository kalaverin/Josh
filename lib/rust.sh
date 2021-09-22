#!/bin/zsh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$HTTP_GET" ] || [ -z "$JOSH" ] || [ -z "$JOSH_BASE" ]; then
        source "`dirname $0`/../run/boot.sh"
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
    bat            # modern replace for cat with syntax highlight
    cargo-update   # packages for auto-update installed crates
    csview         # for commas, tabs, etc
    exa            # fast replace for ls
    fd-find        # fd, fast replace for find for humans
    git-delta      # fast replace for git delta with steroids
    git-interactive-rebase-tool
    lsd            # another ls replacement tool
    mdcat          # Markdown files rendered viewer
    petname        # generate human readable strings
    proximity-sort # path sorter
    rcrawl         # very fast file by pattern in directory
    ripgrep        # rg, fast replace for grep -ri for humans
    rm-improved    # rip, powerful rm replacement with trashcan
    runiq          # fast uniq replacement
    scotty         # directory crawling statistics with search
    sd             # fast sed replacement for humans
    starship       # shell prompt
    tabulate       # autodetect columns in stdin and tabulate
    viu            # print images into terminal
    vivid          # ls colors themes selections system
)  # TODO: checks for missing binaries!

CARGO_OPT_PACKAGES=(
    atuin            # another yet history manager
    bandwhich        # network bandwhich meter
    bingrep          # extract and grep strings from binaries
    broot            # lightweight embeddable file manager
    bump-bin         # versions with semver specification
    choose           # awk for humans
    colorizer        # logs colorizer
    dirstat-rs       # ds, du replace, summary tree
    du-dust          # dust, du replace, verbose tree
    dull             # strip any ANSI (color) sequences from pipe
    dupe-krill       # replace similar (by hash) files with hardlinks
    durt             # du replace, just sum
    feroxbuster      # agressively website dumper
    ffsend           # sharing files tool
    fw               # workspaces manager
    gfold            # git reps in directory branches status
    git-hist         # git history for selected file
    git-local-ignore # local (without .gitignore) git ignore wrapper
    gitui            # terminal UI for git
    hors             # stack overflow answers in terminal
    hyperfine        # full featured time replacement and benchmark tool
    jira-terminal    # Jira client, really
    jql              # select values by path from JSON input for humans
    just             # comfortable system for per project frequently used commands like make test, etc
    logtail          # graphical tail logs in termial
    lolcate-rs       # blazing fast filesystem database
    mrh              # recursively search git reps and return status (detached, tagged, etc)
    onefetch         # graphical statistics for git repository
    paper-terminal   # another yet Markdown printer, naturally like newpaper
    procs            # ps aux replacement for humans
    pueue            # powerful tool to running and management background tasks
    rhit             # very fast nginx log analyzer with graphical stats
    rmesg            # modern dmesg replacement
    scriptisto       # powerful tool, convert every source to executable with build instructions in same file
    so               # stack overflow answers in terminal
    streampager
    tokei            # repository stats
    x8               # websites scan tool
    ytop             # simple htop
    # coreutils        # rust reimplementation for GNU tools
    watchexec-cli    # watchdog for filesystem and runs callback on hit
    git-warp-time    # set mtime to last change time from git
    gip     # show my ip
    genact  # console activity generator
    prose   # reformat text to width
    imdl    # torrent-file helper
    cw      # words, lines, bytes and chars counter
    pgen    # human passphrase generator
    jsonfmt # another json minifier
    rjo     # json generator from key=value args
    xkpwgen         # like pet name
    ff-find   # ff, fd-find interface
    ipgeo   # fast geoloc by hostname/ip
    python-launcher
    rustscan  # scanner around nmap
    loadem    # website load maker
    ntimes    # ntimes 3 -- echo 'lol'
    jfmt      # json minifier
    fblog    # json log viewer
    ruplacer # in file tree replacer
    amber    # in file tree replacer, threaded, mmap
    blockish # view images in terminal
    fcp      # fast cp with threading
    checkpwn # check passwords
    fclones  # find and clean trash
    tidy-viewer # csv prettry printer
    songrec # shazam!
    sbyte   # hexeditor
    gbump   # semver
    jen     # json generator
    yj      # yaml to json
    b0x     # info about input vars
    miniserve  # directory serving over http
    code-minimap  # terminal code minimap
    mandown  # convert markdown to man
    tickrs      # realtime ticker
    investments # stocks tools
    pipecolor  # colorizer
    limber  # elk import export
    dssim   # pictures similar rating
    bottom  # btm, another yet htop
    zoxide  # fast cd, like wd
    binary-security-check
    git-bonsai
    dtool   # code decode swiss knife
    git-trim
    doh-proxy
    encrypted-dns
    diffsitter
    xcompress
    doh-client
    hx
    pingkeeper
    bropages
    qrrs
    connchk
    # skim ?
    vergit
    what-bump
    git-branchless
    gitall
    autocshell
    kras  # colorizer
    ssup
    multi-tunnel
    elephantry-cli
    # estunnel ?
    # file-sniffer
    xplr    # current broken
    silicon
    parallel-disk-usage
    hunter
    tab
    menyoki # screencast
    sheldon
    termscp
    sic     # pictures swiss knife
    t-rec
    lino
    jex
    mprober
    thwack  # find and run
    lms     # threaded rsync for local
    chit    # crates info
    diffr   # word based diff
    gitweb  # git open in browser helper
    lolcrab
    copycat
    repgrep
    runscript
    quickdash # hasher
)

CARGO_BIN="$CARGO_BINARIES/cargo"

function cargo_init() {
    local cache_exe="$CARGO_BINARIES/sccache"

    if [ ! -x "$CARGO_BIN" ]; then
        export RUSTC_WRAPPER=""
        unset RUSTC_WRAPPER

        url='https://sh.rustup.rs'

        $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME="$HOME/.rustup" CARGO_HOME="`dirname $CARGO_BINARIES`" RUSTUP_INIT_SKIP_PATH_CHECK=yes $SHELL -s - --profile minimal --no-modify-path --quiet -y

        if [ $? -gt 0 ] || [ ! -x "$CARGO_BIN" ]; then
            echo " - fatal: cargo \`$CARGO_BIN\` isn't installed"
            return 255
        fi
    fi

    source $HOME/.cargo/env

    if [ ! -x "$cache_exe" ]; then
        $CARGO_BIN install sccache
        if [ ! -x "$cache_exe" ]; then
            echo " - warning: sccache \`$cache_exe\` isn't compiled"
        fi
    fi

    if [ -x "$cache_exe" ]; then
        export RUSTC_WRAPPER="$cache_exe"
    elif [ -x "`lookup sccache`" ]; then
        export RUSTC_WRAPPER="`lookup sccache`"
    else
        export RUSTC_WRAPPER=""
        unset RUSTC_WRAPPER
        echo " - warning: sccache doesn't exists"
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        $CARGO_BIN install cargo-update
        if [ ! -x "$update_exe" ]; then
            echo " - warning: cargo-update \`$update_exe\` isn't compiled"
        fi
    fi

    return 0
}

function cargo_deploy() {
    cargo_init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe \`$CARGO_BIN\` isn't found!"
        return 1
    fi

    $SHELL -c "`realpath $CARGO_BINARIES/rustup` update"

    local retval=0
    for pkg in $@; do
        $CARGO_BIN install $pkg
        if [ "$?" -gt 0 ]; then
            local retval=1
        fi
    done
    cargo_update
    return "$retval"
}

function cargo_extras() {
    cargo_deploy $CARGO_REQ_PACKAGES $CARGO_OPT_PACKAGES
    return 0
}

function cargo_recompile() {
    cargo_init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local packages="$($CARGO_BIN install --list | egrep '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ' | sed -z 's:\n: :g')"
    if [ "$packages" ]; then
        $SHELL -c "$CARGO_BIN install --force $packages"
    fi
}

function cargo_update() {
    cargo_init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        echo " - fatal: cargo-update exe $update_exe isn't found!"
        return 1
    fi

    $CARGO_BIN install-update -a
    return "$?"
}

function rust_env() {
    cargo_init
}
