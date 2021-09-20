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

cd "$DEST/run/"
[ $? -gt 0 ] && return 3

if [ "$JOSH_BRANCH" ]; then
    echo " + fetch Josh branch \`$JOSH_BRANCH\`"

    local cmd="git fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && git checkout --force --quiet $JOSH_BRANCH && git reset --hard $JOSH_BRANCH && git pull --ff-only --no-edit --no-commit --verbose origin $JOSH_BRANCH"

    echo " -> $cmd" && $SHELL -c "$cmd"
    [ $? -gt 0 ] && return 4
fi
echo " + using Josh branch \``git rev-parse --quiet --abbrev-ref HEAD`\`"

. "$DEST/run/strap.sh"

check_requirements && \
prepare_and_deploy && \
replace_existing_installation
