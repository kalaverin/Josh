#!/bin/sh

export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")

. $SOURCE_ROOT/install/check.sh
check_compliance && return 255

if [ ! "$REAL" ]; then
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/install/init.sh

    if [ ! "$REAL" ]; then
        echo " - fatal: init failed"
        return 255
    fi
fi

if [ ! "$HTTP_GET" ]; then
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 255
else
    echo " * http backend: $HTTP_GET" 1>&2
fi

export CONFIG_DIR="$REAL/.config"
export MERGE_DIR="$REAL/josh.base"

cd "$SOURCE_ROOT" &&
git pull origin master && \
. install/units/oh-my-zsh.sh && \
. install/units/utils.sh && \
. install/units/configs.sh && \
. install/units/rust.sh

[ $? -gt 0 ] && return 1

deploy_ohmyzsh && \
deploy_extensions && \
deploy_fzf && \
deploy_httpie && \
deploy_starship && \
config_starship && \
deploy_micro && \
config_micro && \
config_git && \
nano_syntax && \
grep_ignore && \
prepare_cargo && \
deploy_packages $REQUIRED_PACKAGES

[ $? -gt 0 ] && return 2

if [ "$ZSH" != "$SOURCE_ROOT" ]; then
    merge_josh_ohmyzsh && \
    save_previous_installation && \
    rename_and_link

    [ $? -gt 0 ] && return 3

    cd $REAL && echo ' + oh my josh!'
fi
