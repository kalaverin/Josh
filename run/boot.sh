#!/bin/sh

if [ ! "`which git`" ]; then
    echo " - fatal: git required, please install"
    return 1
fi

[ -f "`which -p realpath`" ] && HOME="`realpath $HOME`"
DEST="$HOME/josh.future"

[ -d "$DEST" ] && rm -rf "$DEST"
[ -d "$HOME/josh.base" ] && rm -rf "$HOME/josh.base"

echo " + initial deploy to $DEST"

git clone --depth 1 https://github.com/YaakovTooth/Josh.git $DEST
[ $? -gt 0 ] && return 2


if [ "$JOSH_BRANCH" ]; then
    echo " + using custom JOSH branch \`$JOSH_BRANCH\`"

    GIT="git --git-dir=\"$DEST/.git\" --work-tree=\"$DEST\""
    local cmd="$GIT fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && $GIT checkout --force --quiet $JOSH_BRANCH && $GIT reset --hard $JOSH_BRANCH && $GIT pull origin $JOSH_BRANCH"

    echo " -> $cmd" && $SHELL -c "$cmd"
    [ $? -gt 0 ] && return 3
fi

cd "$DEST/run/"
. "$DEST/run/strap.sh"

check_requirements && \
prepare_and_deploy && \
replace_existing_installation
