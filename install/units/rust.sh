#!/bin/sh

REQUIRED_PACKAGES=(
    bat       # modern replace for cat with syntax highlight
    csview    # for commas, tabs, etc
    exa       # fast replace for ls
    fd-find   # fd, fast replace for find for humans
    git-delta # fast replace for git delta with steroids
    mdcat     # Markdown files rendered viewer
    ripgrep   # rg, fast replace for grep -ri for humans
    starship  # shell prompt
    vivid     # ls colors themes selections system
)

OPTIONAL_PACKAGES=(
    atuin            # another yet history manager
    bandwhich        # network bandwhich meter
    bingrep          # extract and grep strings from binaries
    broot            # lightweight embeddable file manager
    cargo-trim
    choose           # awk for humans
    colorizer        # logs colorizer
    conventional_commits_next_version
    dirstat-rs       # ds, du replace, summary tree
    du-dust          # dust, du replace, verbose tree
    dull             # strip any ANSI (color) sequences from pipe
    dupe-krill       # replace similar (by hash) files with hardlinks
    durt             # du replace, just sum
    feroxbuster      # agressively website dumper
    ffsend           # sharing files tool
    fselect          # SQL-like wrapper around find
    fw               # workspaces manager
    gfold            # git reps in directory branches status
    git-hist         # git history for selected file
    git-local-ignore # local (without .gitignore) git ignore wrapper
    gitui            # terminal UI for git
    hors             # stack overflow answers in terminal
    huniq            # very fast sort | uniq replacement
    hyperfine        # full featured time replacement and benchmark tool
    jira-terminal    # Jira client, really
    jql              # select values by path from JSON input for humans
    just             # comfortable system for per project frequently used commands like make test, etc
    logtail          # graphical tail logs in termial
    lolcate-rs       # blazing fast filesystem database
    lsd              # another ls replacement tool
    mrh              # recursively search git reps and return status (detached, tagged, etc)
    onefetch         # graphical statistics for git repository
    paper-terminal   # another yet Markdown printer, naturally like newpaper
    petname          # generate human readable strings
    procs            # ps aux replacement for humans
    pueue            # powerful tool to running and management background tasks
    rcrawl           # very fast file by pattern in directory
    rhit             # very fast nginx log analyzer with graphical stats
    rm-improved      # rip, powerful rm replacement with trashcan
    rmesg            # modern dmesg replacement
    scotty           # directory crawling statistics with search
    scout            # another one fuzzy search pipeliner
    scriptisto       # powerful tool, convert every source to executable with build instructions in same file
    sd               # fast sed replacement for humans
    so               # stack overflow answers in terminal
    streampager
    syncat           # cat with syntax
    tabulate         # autodetect columns in stdin and tabulate
    tokei            # sources stats
    viu              # print images into terminal
    x8               # websites scan tool
    ytop             # simple htop
)

function set_defaults() {
    if [ ! "$REAL" ]; then
        export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
        echo " + init from $SOURCE_ROOT"
        . $SOURCE_ROOT/install/init.sh

        if [ ! "$REAL" ]; then
            echo " - fatal: init failed"
            return 255
        fi
    fi
    if [ ! "$HTTP_GET" ]; then
        echo " - fatal: init failed, HTTP_GET empty"
        return 255
    fi
    return 0
}

function prepare_cargo() {
    set_defaults
    local CARGO_DIR="$REAL/.cargo/bin"
    local CARGO_EXE="$CARGO_DIR/cargo"
    if [ ! -d "$CARGO_DIR" ] && mkdir -p "$CARGO_DIR"

    url='https://sh.rustup.rs'
    if [ ! -f "$CARGO_EXE" ]; then
        $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --quiet -y
        if [ $? -gt 0 ]; then
            $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --verbose -y
            echo " - fatal: cargo deploy failed"
            return 1
        fi
    else
        $SHELL -c "`realpath $CARGO_DIR/rustup` update"
    fi

    if [ ! -f "$CARGO_DIR/sccache" ]; then
        $CARGO_EXE install sccache
    fi

    if [ -f "`which sccache`" ]; then
        export RUSTC_WRAPPER=`which sccache`
    fi
    return 0
}

function deploy_packages() {
    set_defaults
    local CARGO_DIR="$REAL/.cargo/bin"
    local CARGO_EXE="$CARGO_DIR/cargo"
    if [ ! -d "$CARGO_DIR" ] && mkdir -p "$CARGO_DIR"

    for pkg in $@; do
        $CARGO_EXE install $pkg
    done
    return 0
}

function deploy_extras() {
    deploy_packages $REQUIRED_PACKAGES
    deploy_packages $OPTIONAL_PACKAGES
    return 0
}
