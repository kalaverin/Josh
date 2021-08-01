if [ ! "`which git`" ]; then
    echo " - fatal: git required"
    return 1
fi

DEST="`realpath ~/josh.future`"
[ -d $DEST ] && rm -rf "$DEST"
echo " + deploy Josh to $DEST"

git clone --depth 1 https://github.com/YaakovTooth/Josh.git $DEST
[ $? -gt 0 ] && return 2

cd "$DEST/install/" && $SHELL "$DEST/install/strap.sh"
