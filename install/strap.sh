#!/bin/sh

export INSTALL_ROOT=`git rev-parse --quiet --show-toplevel`

. $INSTALL_ROOT/install/init.sh
[ $? -gt 0 ] && echo " - initialization failure"
if [ ! "$HTTP_GET" ]; then
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 1
else
    echo " * http backend: $HTTP_GET" 1>&2
fi

export CONF_DIR="$REAL/.config"
export TEMP_DIR="$REAL/josh.base"

$SHELL $INSTALL_ROOT/install/units/oh-my-zsh.sh
$SHELL $INSTALL_ROOT/install/units/utils.sh
$SHELL $INSTALL_ROOT/install/units/configs.sh
$SHELL $INSTALL_ROOT/install/units/rust.sh
