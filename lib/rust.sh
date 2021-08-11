#!/bin/sh

CARGO_REQ_PACKAGES=(
    bat            # modern replace for cat with syntax highlight
    broot          # lightweight embeddable file manager
    csview         # for commas, tabs, etc
    exa            # fast replace for ls
    fd-find        # fd, fast replace for find for humans
    git-delta      # fast replace for git delta with steroids
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
)

CARGO_OPT_PACKAGES=(
    atuin            # another yet history manager
    bandwhich        # network bandwhich meter
    bingrep          # extract and grep strings from binaries
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
)

function set_defaults() {
    if [ ! "$REAL" ]; then
        export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
        echo " + init from $SOURCE_ROOT"
        . $SOURCE_ROOT/run/init.sh

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

function cargo_init() {
    set_defaults

    local CARGO_DIR="$REAL/.cargo/bin"
    if [ ! -d "$CARGO_DIR" ] && mkdir -p "$CARGO_DIR"

    local CACHE_EXE="$CARGO_DIR/sccache"
    export CARGO_EXE="$CARGO_DIR/cargo"

    url='https://sh.rustup.rs'
    if [ ! -f "$CARGO_EXE" ]; then
        $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --quiet -y
        if [ $? -gt 0 ]; then
            $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --verbose -y
            echo " - fatal: cargo deploy failed!"
            return 1
        fi
        if [ ! -f "$CARGO_EXE" ]; then
            echo " - fatal: cargo isn't installed ($CARGO_EXE)"
            return 255
        fi
    else
        $SHELL -c "`realpath $CARGO_DIR/rustup` update"
    fi

    if [ ! -f "$CACHE_EXE" ]; then
        $CARGO_EXE install sccache
        if [ ! -f "$CACHE_EXE" ]; then
            echo " - warning: sccache isn't compiled ($CACHE_EXE)"
        fi
    fi

    if [ -f "$CACHE_EXE" ]; then
        export RUSTC_WRAPPER="$CACHE_EXE"
    elif [ -f "`which sccache`" ]; then
        export RUSTC_WRAPPER=`which sccache`
    else
        echo " - warning: sccache doesn't exists"
    fi

    return 0
}

function cargo_deploy() {
    cargo_init || return $?
    if [ ! -f "$CARGO_EXE" ]; then
        echo " - fatal: cargo exe $CARGO_EXE isn't found!"
        return 1
    fi
    for pkg in $@; do
        $CARGO_EXE install $pkg
    done
    return 0
}

function cargo_extras() {
    cargo_deploy $CARGO_REQ_PACKAGES $CARGO_OPT_PACKAGES
    return 0
}
