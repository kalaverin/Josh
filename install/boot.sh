if [ ! "`which git`" ]; then
    echo " - fatal: git required"
    return 1
fi

DEST="`realpath ~`/josh.future"
[ -d $DEST ] && rm -rf "$DEST"
echo " + initial deploy to $DEST"

git clone --depth 1 https://github.com/YaakovTooth/Josh.git $DEST
[ $? -gt 0 ] && return 2

cd "$DEST/install/"
. "$DEST/install/strap.sh"

check_requirements && \
prepare_and_deploy && \
replace_existing_installation
