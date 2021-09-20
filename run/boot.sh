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
    echo " * using custom JOSH branch $JOSH_BRANCH"
    local git_exe="git --git-dir=\"$DEST/.git\" --work-tree=\"$DEST\""
    $SHELL -c "$git_exe fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && $git_exe checkout --force --quiet $JOSH_BRANCH && $git_exe git reset --hard $JOSH_BRANCH && $git_exe git pull origin $JOSH_BRANCH"
    [ $? -gt 0 ] && return 3
fi

cd "$DEST/run/"
. "$DEST/run/strap.sh"

check_requirements && \
prepare_and_deploy && \
replace_existing_installation
