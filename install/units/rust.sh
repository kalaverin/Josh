#!/bin/sh

REQUIRED_PACKAGES=(
    bat       # modern replace for cat with syntax highlight
    csview    # for commas, tabs, etc
    exa       # fast replace for ls
    fd-find   # fd, fast replace for find for humans
    git-delta # fast replace for git delta with steroids
    ripgrep   # rg, fast replace for grep -ri for humans
    starship  # shell prompt
)

OPTIONAL_PACKAGES=(
    bandwhich        # network bandwhich meter
    bingrep          # extract and grep strings from binaries
    colorizer        # logs colorizer
    dirstat-rs       # ds, du replace, summary tree
    du-dust          # dust, du replace, verbose tree
    dull             # strip any ANSI (color) sequences from pipe
    dupe-krill       # replace similar (by hash) files with hardlinks
    durt             # du replace, just sum
    fselect          # SQL-like wrapper around find
    gfold            # git reps in directory branches status
    git-hist         # git history for selected file
    git-local-ignore # local (without .gitignore) git ignore wrapper
    gitui            # terminal UI for git
    hors             # stack overflow answers in terminal
    huniq            # very fast sort | uniq replacement
    hyperfine        # full featured time replacement and benchmark tool
    jql              # select values by path from JSON input for humans
    logtail          # graphical tail logs in termial
    lsd              # another ls replacement tool
    mdcat            # Markdown files rendered viewer
    mrh              # recursively search git reps and return status (detached, tagged, etc)
    onefetch         # graphical statistics for git repository
    procs            # ps aux replacement for humans
    rcrawl           # very fast file by pattern in directory
    rhit             # very fast nginx log analyzer with graphical stats
    rm-improved      # rip, powerful rm replacement with trashcan
    rmesg            # modern dmesg replacement
    scotty           # directory crawling statistics with search
    scriptisto       # powerful tool, convert every source to executable with build instructions in same file
    sd               # fast sed replacement for humans
    so               # stack overflow answers in terminal
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
            exit 255
        fi
    fi
    if [ ! "$HTTP_GET" ]; then
        echo " - fatal: init failed, HTTP_GET empty"
        exit 255
    fi
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
            exit 1
        fi
    else
        $SHELL -c "`realpath $CARGO_DIR/rustup` update"
    fi

    if [ ! -f "`realpath $CARGO_DIR/sccache`" ]; then
        $CARGO_EXE install sccache
    fi

    if [ -f "`which sccache`" ]; then
        export RUSTC_WRAPPER=`which sccache`
    fi
}

function deploy_packages() {
    set_defaults
    local CARGO_DIR="$REAL/.cargo/bin"
    local CARGO_EXE="$CARGO_DIR/cargo"
    if [ ! -d "$CARGO_DIR" ] && mkdir -p "$CARGO_DIR"

    for pkg in $@; do
        $CARGO_EXE install $pkg
    done
}

function deploy_extras() {
    deploy_packages $OPTIONAL_PACKAGES
}
