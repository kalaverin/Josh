#!/bin/sh

if [ ! "`which git`" ]; then
    echo " - fatal: git required"
    return 1
fi

if [ -f "`which -p realpath`" ]; then
    HOME="`realpath $HOME`"
fi
DEST="$HOME/josh.future"

[ -d "$DEST" ] && rm -rf "$DEST"
[ -d "$HOME/josh.base" ] && rm -rf "$HOME/josh.base"

echo " + initial deploy to $DEST"

git clone --depth 1 https://github.com/YaakovTooth/Josh.git $DEST
[ $? -gt 0 ] && return 2

cd "$DEST/run/"
. "$DEST/run/strap.sh"

check_requirements && \
prepare_and_deploy && \
replace_existing_installation
