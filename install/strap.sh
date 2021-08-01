#!/bin/sh

export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")

if [ ! "$REAL" ]; then
    . $SOURCE_ROOT/install/init.sh
    if [ ! "$REAL" ]; then
        echo " - fatal: init failed"
        exit 255
    fi
fi

if [ ! "$HTTP_GET" ]; then
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 255
else
    echo " * http backend: $HTTP_GET" 1>&2
fi

export CONFIG_DIR="$REAL/.config"
export JOSH_MERGE_DIR="$REAL/josh.base"

. $SOURCE_ROOT/install/units/oh-my-zsh.sh && \
. $SOURCE_ROOT/install/units/utils.sh && \
. $SOURCE_ROOT/install/units/configs.sh && \
. $SOURCE_ROOT/install/units/rust.sh

[ $? -gt 0 ] && return 1

deploy_ohmyzsh && \
deploy_extensions && \
deploy_fzf && \
deploy_starship && \
config_starship && \
deploy_micro && \
config_micro && \
prepare_cargo && \
deploy_packages $REQUIRED_PACKAGES

[ $? -gt 0 ] && return 2
