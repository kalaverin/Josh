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


# ——— after install all required dependencies — finalize installation

if [ -d "~/josh.future" ]; then
    echo " + ~/josh.future merging into ~/josh.base/custom/plugins/"
    mv ~/josh.future ~/josh.base/custom/plugins/josh

elif [ -d "~/josh.base/custom/plugins/josh" ]; then
    echo " + ~/josh.future already merged ~/josh.base/custom/plugins/"

else
    echo " - fatal: something wrong"
    exit 3
fi


# ——— backup previous installation and configs

if [ -d $ZSH ]; then
    # another josh installation found, move backup

    dst="$ZSH-(`date "+%Y.%m%d.%H%M"`)-backup"
    echo " + another Josh found, backup to $dst"

    mv "$ZSH" "$dst"
    if [ $? -gt 0 ]; then
        echo " - backup $ZSH failed"
        exit 4
    fi

    if [ -e "~/.zshrc" ]; then
        if [ ! -d $dst ]; then
            mkdir -p $dst
        fi
        cp -L "~/.zshrc" "$dst/.zshrc"
        if [ $? -gt 0 ]; then
            echo " - backup ~/.zshrc failed"
            exit 4
        fi
        rm "~/.zshrc"
    fi

elif [ -e "~/.zshrc" ]; then
    # .zshrc exists from non-josh installation

    dst="~/.zshrc-(`date "+%Y.%m%d.%H%M"`)-backup"
    echo " + backup old .zshrc to"

    cp -L "~/.zshrc" "$dst"
    if [ $? -gt 0 ]; then
        echo " - backup ~/.zshrc failed"
        exit 4
    fi
    rm "~/.zshrc"
fi


# ——— set current installation as main and link config

mv "~/josh.base" "$ZSH" && ln -s $JOSH/.zshrc ~/.zshrc && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme
if [ $? -gt 0 ]; then
    echo ' - fatal: linkage failed'
    exit 5
fi
