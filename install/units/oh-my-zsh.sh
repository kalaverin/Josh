#!/bin/sh

if [ ! "$REAL" ]; then
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/install/init.sh

    if [ ! "$REAL" ]; then
        echo " - fatal: init failed"
        exit 255
    fi
fi
if [ ! "$HTTP_GET" ]; then
    echo " - fatal: init failed, HTTP_GET empty"
    exit 255
fi
if [ ! "$MERGE_DIR" ]; then
    echo " - fatal: init failed, MERGE_DIR empty"
    exit 255
fi

PLUGIN_DIR="$MERGE_DIR/custom/plugins"
PACKAGES=(
    "https://github.com/b4b4r07/emoji-cli $PLUGIN_DIR/emoji-cli"
    "https://github.com/chrissicool/zsh-256color $PLUGIN_DIR/zsh-256color"
    "https://github.com/hlissner/zsh-autopair.git $PLUGIN_DIR/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $PLUGIN_DIR/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $PLUGIN_DIR/zsh-async"
    "https://github.com/mollifier/anyframe.git $PLUGIN_DIR/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $PLUGIN_DIR/zsh-fuzzy-search-and-edit"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $PLUGIN_DIR/autoupdate"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $PLUGIN_DIR/zsh-syntax-highlighting-filetypes"
    "https://github.com/wfxr/forgit.git $PLUGIN_DIR/forgit"
    "https://github.com/zdharma/history-search-multi-word.git $PLUGIN_DIR/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $PLUGIN_DIR/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $PLUGIN_DIR/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $PLUGIN_DIR/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGIN_DIR/zsh-syntax-highlighting"
    "--recursive https://github.com/joel-porquet/zsh-dircolors-solarized.git $PLUGIN_DIR/zsh-dircolors-solarized"
)


# ——- first, clone oh-my-zsh as core

function deploy_ohmyzsh() {
    url='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
    if [ -d "$MERGE_DIR" ]; then
        echo " * oh-my-zsh already in $MERGE_DIR"
        cd $MERGE_DIR && git reset --hard && git pull origin master
    else
        echo " + deploy oh-my-zsh to $MERGE_DIR"
        $SHELL -c "$HTTP_GET $url | CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$MERGE_DIR bash -s - --unattended --keep-zshrc"
        [ $? -gt 0 ] && return 1
    fi
    return 0
}


# ——- then clone git-based extensions

function deploy_extensions() {
    clone="`which git` clone --depth 1"
    if [ ! -d "$PLUGIN_DIR" ]; then
        mkdir -p "$PLUGIN_DIR"
    fi
    if [ "`find $PLUGIN_DIR -type d -maxdepth 1 | wc -l`" -gt "${#PACKAGES[@]}" ]; then
        echo " * extensions already deployed to $PLUGIN_DIR"
    else
        echo " + clone extensions to $PLUGIN_DIR"
        for pkg in "${PACKAGES[@]}"; do
            $SHELL -c "$clone $pkg"
            if [ $? -gt 0 ]; then
                echo " - clone plugin failed: $clone $pkg"
            else
                echo " - clone plugin ok: $clone $pkg"
            fi
        done
    fi
    return 0
}


# ——— after install all required dependencies — finalize installation

function merge_josh_ohmyzsh() {
    if [ -d "$SOURCE_ROOT" ]; then
        echo " + $SOURCE_ROOT merging into $MERGE_DIR/custom/plugins/"
        mv $SOURCE_ROOT $MERGE_DIR/custom/plugins/josh

    elif [ -d "$MERGE_DIR/custom/plugins/josh" ]; then
        echo " + $SOURCE_ROOT already merged $MERGE_DIR/custom/plugins/"

    else
        echo " - fatal: something wrong"
        return 3
    fi
    return 0
}


# ——— backup previous installation and configs

function save_previous_installation() {
    if [ -d "$ZSH" ]; then
        # another josh installation found, move backup

        dst="$ZSH-(`date "+%Y.%m%d.%H%M"`)-backup"
        echo " + another Josh found, backup to $dst"

        mv "$ZSH" "$dst"
        if [ $? -gt 0 ]; then
            echo " - backup $ZSH failed"
            return 4
        fi

    elif [ -e "$REAL/.zshrc" ]; then
        # .zshrc exists from non-josh installation

        dst="$REAL/.zshrc-(`date "+%Y.%m%d.%H%M"`)-backup"
        echo " + backup old .zshrc to $dst"

        cp -L "$REAL/.zshrc" "$dst"
        if [ $? -gt 0 ]; then
            echo " - backup $REAL/.zshrc failed"
            return 4
        fi
        rm "$REAL/.zshrc"
    fi
    return 0
}


# ——— set current installation as main and link config

function rename_and_link() {
    mv "$MERGE_DIR" "$ZSH"
    ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme

    if [ ! -e "$REAL/.zshrc" ]; then
        ln -s $JOSH/.zshrc ~/.zshrc
        if [ $? -gt 0 ]; then
            echo ' - fatal: linkage failed'
            return 5
        fi
    fi
    return 0
}
