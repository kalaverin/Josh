#!/bin/sh

if [ ! "$HTTP_GET" ]; then
    echo " - fatal: init failed, HTTP_GET empty"
    exit 255
fi
if [ ! "$JOSH_MERGE_DIR" ]; then
    echo " - fatal: init failed, JOSH_MERGE_DIR empty"
    exit 255
fi

PLUGIN_DIR="$JOSH_MERGE_DIR/custom/plugins"
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
    if [ -d "$JOSH_MERGE_DIR" ]; then
        echo " * oh-my-zsh already in $JOSH_MERGE_DIR"
        cd $JOSH_MERGE_DIR && git reset --hard && git pull origin master
    else
        echo " + deploy oh-my-zsh to $JOSH_MERGE_DIR"
        $SHELL -c "$HTTP_GET $url | CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$JOSH_MERGE_DIR bash -s - --unattended --keep-zshrc"
        ret="$?"
        echo ">$ret<"
        [ $ret -gt 0 ] && return 1
    fi
}


# ——- then clone git-based extensions

function deploy_extensions() {
    clone="`which git` clone --depth 1"
    if [ ! -d "$PLUGIN_DIR" ]; then
        mkdir -p "$PLUGIN_DIR"
        echo " + clone extensions to $PLUGIN_DIR"
        for pkg in "${PACKAGES[@]}"; do
            $SHELL -c "$clone $pkg"
            if [ $? -gt 0 ]; then
                echo " - clone plugin failed: $clone $pkg"
            else
                echo " - clone plugin ok: $clone $pkg"
            fi
        done
    else
        echo " * extensions already in $PLUGIN_DIR"
    fi
}
