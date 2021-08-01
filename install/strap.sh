#!/bin/sh

export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")

if [ ! "$REAL" ]; then
    echo " + init from $SOURCE_ROOT"
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
deploy_starship && \
config_starship && \
deploy_micro && \
config_micro && \
prepare_cargo && \
deploy_packages $REQUIRED_PACKAGES

[ $? -gt 0 ] && return 2


if [ "$ZSH" != "$SOURCE_ROOT" ]; then

    # ——— after install all required dependencies — finalize installation

    if [ -d "$SOURCE_ROOT" ]; then
        echo " + $SOURCE_ROOT merging into $MERGE_DIR/custom/plugins/"
        mv $SOURCE_ROOT $MERGE_DIR/custom/plugins/josh

    elif [ -d "$MERGE_DIR/custom/plugins/josh" ]; then
        echo " + $SOURCE_ROOT already merged $MERGE_DIR/custom/plugins/"

    else
        echo " - fatal: something wrong"
        exit 3
    fi


    # ——— backup previous installation and configs

    if [ -d "$ZSH" ]; then
        # another josh installation found, move backup

        dst="$ZSH-(`date "+%Y.%m%d.%H%M"`)-backup"
        echo " + another Josh found, backup to $dst"

        mv "$ZSH" "$dst"
        if [ $? -gt 0 ]; then
            echo " - backup $ZSH failed"
            exit 4
        fi

        if [ -e "$REAL/.zshrc" ]; then
            if [ ! -d $dst ]; then
                mkdir -p $dst
            fi
            cp -L "$REAL/.zshrc" "$dst/.zshrc"
            if [ $? -gt 0 ]; then
                echo " - backup $REAL/.zshrc failed"
                exit 4
            fi
            rm "$REAL/.zshrc"
        fi

    elif [ -e "$REAL/.zshrc" ]; then
        # .zshrc exists from non-josh installation

        dst="$REAL/.zshrc-(`date "+%Y.%m%d.%H%M"`)-backup"
        echo " + backup old .zshrc to $dst"

        cp -L "$REAL/.zshrc" "$dst"
        if [ $? -gt 0 ]; then
            echo " - backup $REAL/.zshrc failed"
            exit 4
        fi
        rm "$REAL/.zshrc"
    fi


    # ——— set current installation as main and link config

    mv "$MERGE_DIR" "$ZSH" && ln -s $JOSH/.zshrc ~/.zshrc && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme
    if [ $? -gt 0 ]; then
        echo ' - fatal: linkage failed'
        exit 5
    fi
    echo " + Josh deploy success, enjoy!"
    exec zsh
fi
