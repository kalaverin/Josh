RUST_URL='https://sh.rustup.rs'

RUST_PACKAGES=(
    bandwhich
    bat
    bingrep
    colorizer
    csview
    dirstat-rs
    du-dust
    dull
    dupe-krill
    durt
    exa
    fd-find
    fselect
    gfold
    git-delta
    git-hist
    git-local-ignore
    gitui
    hors
    huniq
    hyperfine
    jql
    logtail
    lsd
    mdcat
    mrh
    onefetch
    procs
    rcrawl
    rhit
    ripgrep
    rm-improved
    rmesg
    scotty
    scriptisto
    sd
    so
    starship
    syncat
    tabulate
    tokei
    viu
    x8
    ytop
)


# if [ ! $REAL ]; then
#     local JOSH=$(sh -c "dirname `realpath ~/.zshrc`")
#     source "$JOSH/install/init.sh"
# fi

export CARGO_BIN=`realpath $REAL/.cargo/bin`
cargo=`realpath $CARGO_BIN/cargo`
if [ ! -f $cargo ]; then
    $SHELL -c "$HTTP_GET $RUST_URL" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --quiet -y

    if [ $? -gt 0 ] && $SHELL -c "$HTTP_GET $RUST_URL" | RUSTUP_HOME=~/.rustup CARGO_HOME=~/.cargo RUSTUP_INIT_SKIP_PATH_CHECK=yes bash -s - --profile minimal --no-modify-path --verbose -y

    if [ $? -gt 0 ]; then
        echo " - fatal: cargo deploy failed"
        return 1
    fi
fi

if [ ! -f `realpath $CARGO_BIN/sccache` ]; then
    $cargo install sccache
    if [ `which sccache` ]; then
        export RUSTC_WRAPPER=`which sccache`
    fi
fi

for pkg in $RUST_PACKAGES; do
    $cargo install $pkg
done
