#!/bin/zsh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    [ -z "$HTTP_GET" ] && source "`dirname $0`/../boot.sh"

    if [ -n "$JOSH_DEST" ]; then
        DEST="$JOSH_DEST"
        if [ -z "$OMZ_PLUGIN_DIR" ]; then
            echo " + install oh-my-zsh to \`$DEST\`"
        fi
    else
        DEST="$JOSH"
    fi
fi

OMZ_PLUGIN_DIR="$DEST/custom/plugins"
PACKAGES=(
    "https://github.com/alecthomas/ondir.git $OMZ_PLUGIN_DIR/ondir"
    "https://github.com/b4b4r07/emoji-cli $OMZ_PLUGIN_DIR/emoji-cli"
    "https://github.com/chrissicool/zsh-256color $OMZ_PLUGIN_DIR/zsh-256color"
    "https://github.com/hlissner/zsh-autopair.git $OMZ_PLUGIN_DIR/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $OMZ_PLUGIN_DIR/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $OMZ_PLUGIN_DIR/zsh-async"
    "https://github.com/mollifier/anyframe.git $OMZ_PLUGIN_DIR/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $OMZ_PLUGIN_DIR/zsh-fuzzy-search-and-edit"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $OMZ_PLUGIN_DIR/autoupdate"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $OMZ_PLUGIN_DIR/zsh-syntax-highlighting-filetypes"
    "https://github.com/wfxr/forgit.git $OMZ_PLUGIN_DIR/forgit"
    "https://github.com/zdharma/history-search-multi-word.git $OMZ_PLUGIN_DIR/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $OMZ_PLUGIN_DIR/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $OMZ_PLUGIN_DIR/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $OMZ_PLUGIN_DIR/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $OMZ_PLUGIN_DIR/zsh-syntax-highlighting"
)


# ——- first, clone oh-my-zsh as core

function deploy_ohmyzsh() {
    local cwd="`pwd`"
    url='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
    if [ -d "$JOSH_DEST" ]; then
        echo " * oh-my-zsh already in $JOSH_DEST"
        builtin cd "$JOSH_DEST" && git reset --hard && git pull origin master; builtin cd "$cwd"
    else
        echo " + deploy oh-my-zsh to $JOSH_DEST"
        $SHELL -c "$HTTP_GET $url | CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$JOSH_DEST $SHELL -s - --unattended --keep-zshrc"
        [ $? -gt 0 ] && return 1
    fi
    return 0
}


# ——- then clone git-based extensions

function deploy_extensions() {
    clone="`lookup git` clone --depth 1"
    if [ ! -d "$OMZ_PLUGIN_DIR" ]; then
        mkdir -p "$OMZ_PLUGIN_DIR"
    fi
    if [ "`find $OMZ_PLUGIN_DIR -type d -maxdepth 1 | wc -l`" -gt "${#PACKAGES[@]}" ]; then
        echo " * extensions already deployed to $OMZ_PLUGIN_DIR"
    else
        echo " + clone extensions to $OMZ_PLUGIN_DIR"
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
    if [ -d "$JOSH_BASE" ]; then
        echo " + $JOSH_BASE move into $JOSH_DEST/custom/plugins/"
        mv $JOSH_BASE $JOSH_DEST/custom/plugins/josh

    elif [ -d "$JOSH_DEST/custom/plugins/josh" ]; then
        echo " + $JOSH_BASE already moved to $JOSH_DEST/custom/plugins/"

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

        dst="$ZSH-`date "+%Y.%m%d.%H%M"`-backup"
        echo " + another Josh found, backup to $dst"

        mv "$ZSH" "$dst"
        if [ $? -gt 0 ]; then
            echo " - warning: backup $ZSH failed"
            return 4
        fi

    elif [ -f "$HOME/.zshrc" ]; then
        # .zshrc exists from non-josh installation

        dst="$HOME/.zshrc-`date "+%Y.%m%d.%H%M"`-backup"
        echo " + backup old .zshrc to $dst"

        cp -L "$HOME/.zshrc" "$dst" || mv "$HOME/.zshrc" "$dst"
        if [ $? -gt 0 ]; then
            echo " - warning: backup $HOME/.zshrc failed"
            return 4
        fi
        rm "$HOME/.zshrc"
    fi
    return 0
}


# ——— set current installation as main and link config

function rename_and_link() {
    if [ "$JOSH_DEST" = "$ZSH" ]; then
        return 1
    fi

    echo " + finally, rename $JOSH_DEST -> $ZSH"
    mv "$JOSH_DEST" "$ZSH" && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme

    if [ ! -e "$HOME/.zshrc" ]; then
        ln -s $ZSH/custom/plugins/josh/.zshrc $HOME/.zshrc
        if [ $? -gt 0 ]; then
            echo " - fatal: can't create symlink $ZSH/custom/plugins/josh/.zshrc -> $HOME/.zshrc"
            return 1
        fi
    fi
    return 0
}
