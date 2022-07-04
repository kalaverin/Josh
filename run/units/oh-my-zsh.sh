#!/bin/zsh

zmodload zsh/datetime


if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$HTTP_GET" ]; then
        warn $0 "HTTP_GET isn't set, PWD '$PWD', eval $(dirname $0)/../init.sh"

        [ -z "$HTTP_GET" ] && source "$(dirname $0)/../init.sh"
        [ -z "$HTTP_GET" ] && source "run/init.sh"

        if [ -z "$HTTP_GET" ]; then
            warn $0 "HTTP_GET isn't set"
            return 1
        fi
    fi

    if [ -n "$JOSH_DEST" ]; then
        DEST="$JOSH_DEST"
        if [ -z "$OMZ_PLUGIN_DIR" ]; then
            info $0 "install oh-my-zsh to '$DEST'"
        fi
    else
        DEST="$ZSH"
    fi

    if [ -z "$DEST" ]; then
        fail $0 "DEST isn't set"
    fi
fi


OMZ_PLUGIN_DIR="$DEST/custom/plugins"
PACKAGES=(
    "https://github.com/MestreLion/git-tools.git $OMZ_PLUGIN_DIR/git-tools"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $OMZ_PLUGIN_DIR/autoupdate"
    "https://github.com/alecthomas/ondir.git $OMZ_PLUGIN_DIR/ondir"
    "https://github.com/chrissicool/zsh-256color $OMZ_PLUGIN_DIR/zsh-256color"
    "https://github.com/djui/alias-tips.git $OMZ_PLUGIN_DIR/alias-tips"
    "https://github.com/facebook/PathPicker.git $OMZ_PLUGIN_DIR/fpp"
    "https://github.com/hlissner/zsh-autopair.git $OMZ_PLUGIN_DIR/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $OMZ_PLUGIN_DIR/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $OMZ_PLUGIN_DIR/zsh-async"
    "https://github.com/mollifier/anyframe.git $OMZ_PLUGIN_DIR/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $OMZ_PLUGIN_DIR/zsh-fuzzy-search-and-edit"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $OMZ_PLUGIN_DIR/zsh-syntax-highlighting-filetypes"
    "https://github.com/wfxr/forgit.git $OMZ_PLUGIN_DIR/forgit"
    "https://github.com/zdharma-continuum/history-search-multi-word.git $OMZ_PLUGIN_DIR/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $OMZ_PLUGIN_DIR/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $OMZ_PLUGIN_DIR/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $OMZ_PLUGIN_DIR/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $OMZ_PLUGIN_DIR/zsh-syntax-highlighting"
)


# ——- first, clone oh-my-zsh as core

function __setup.omz.deploy_ohmyzsh {
    local cwd="$PWD"
    local url='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'

    if [ -z "$HTTP_GET" ]; then
        fail $0 "HTTP_GET isn't set"
        return 1
    fi

    if [ -d "$JOSH_DEST" ]; then
        info $0 "oh-my-zsh already in '$JOSH_DEST'"
        builtin cd "$JOSH_DEST" && git pull origin; builtin cd "$cwd"

    else
        info $0 "deploy oh-my-zsh to '$JOSH_DEST'"
        $SHELL -c "$HTTP_GET $url | CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$JOSH_DEST $SHELL -s - --unattended --keep-zshrc"

        if [ "$?" -gt 0 ] || [ ! -f "$JOSH_DEST/oh-my-zsh.sh" ]; then
            fail $0 "something went wrong"
            return 2
        fi
    fi
}


# ——- then clone git-based extensions

function __setup.omz.deploy_extensions {
    if [ -z "$OMZ_PLUGIN_DIR" ]; then
        info $0 "plugins dir isn't set"
        return 1
    fi

    [ ! -d "$OMZ_PLUGIN_DIR" ] && mkdir -p "$OMZ_PLUGIN_DIR"
    if [ ! -d "$OMZ_PLUGIN_DIR" ]; then
        fail $0 "binary dir doesn't exist, OMZ_PLUGIN_DIR '$OMZ_PLUGIN_DIR'"
        return 2
    fi

    info $0 "deploy to '$OMZ_PLUGIN_DIR'"

    for pkg in "${PACKAGES[@]}"; do
        local dst="$OMZ_PLUGIN_DIR/$(fs.basename $pkg)"
        if [ ! -x "$dst/.git" ]; then
            local verb='clone'
            $SHELL -c "git clone --depth 1 $pkg"

        else
            let fetch_every="${UPDATE_ZSH_DAYS:-1} * 86400"
            local last_fetch="$(fs.mtime "$dst/.git/FETCH_HEAD" 2>/dev/null)"
            [ -z "$last_fetch" ] && local last_fetch=0

            let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"
            if [ "$need_fetch" -gt 0 ]; then
                local verb='pull'
                local branch="$(git --git-dir="$dst/.git" --work-tree="$dst/" rev-parse --quiet --abbrev-ref HEAD)"

                if [ -z "$branch" ]; then
                    fail $0 "get branch for $pkg in '$dst'"
                    continue
                else
                    git --git-dir="$dst/.git" --work-tree="$dst/" pull origin "$branch"

                    if [ -x "$(which git-restore-mtime)" ]; then
                        git-restore-mtime --skip-missing --work-tree "$dst/" --git-dir "$dst/.git/"
                    fi
                fi
            else
                local verb='skip fresh'
            fi
        fi

        if [ "$?" -gt 0 ]; then
            warn $0 "$verb error $pkg"
        else
            info $0 "$verb success $pkg"
        fi
    done

    info $0 "${#PACKAGES[@]} complete"
}


# ——— after install all required dependencies — finalize installation

function __setup.omz.merge_ash_ohmyzsh {
    if [ -d "$JOSH_BASE" ]; then
        info $0 "'$JOSH_BASE' move into '$JOSH_DEST/custom/plugins/'"
        mv $JOSH_BASE $JOSH_DEST/custom/plugins/josh

    elif [ -d "$JOSH_DEST/custom/plugins/josh" ]; then
        warn $0 "'$JOSH_BASE' already in '$JOSH_DEST/custom/plugins/'"

    else
        fail $0 "something went wrong"
        return 1
    fi
}


# ——— backup previous installation and configs

function __setup.omz.save_previous_installation {
    if [ -d "$ZSH" ]; then
        # another josh installation found, move backup

        local dst="$ZSH-$(date "+%Y.%m%d.%H%M")-backup"
        warn $0 "another Josh found, backup to '$dst'"

        mv "$ZSH" "$dst"
        if [ $? -gt 0 ]; then
            fail $0 "backup '$ZSH' failed"
            return 1
        fi
    fi

    if [ -f "$HOME/.zshrc" ]; then
        # .zshrc exists from non-josh installation

        local dst="$HOME/.zshrc-`date "+%Y.%m%d.%H%M"`-backup"
        info $0 "backup old .zshrc to '$dst'"

        cp -L "$HOME/.zshrc" "$dst" || mv "$HOME/.zshrc" "$dst"
        if [ $? -gt 0 ]; then
            fail $0 "backup '$HOME/.zshrc' failed"
            return 2
        fi
        rm "$HOME/.zshrc"
    fi
}


# ——— set current installation as main and link config

function __setup.omz.rename_and_link {
    if [ "$JOSH_DEST" = "$ZSH" ]; then
        return 1
    fi

    info $0 "finally, rename '$JOSH_DEST' -> '$ZSH'"
    mv "$JOSH_DEST" "$ZSH" && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme

    dst="$(date "+%Y.%m%d.%H%M").bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc-$dst" 2>/dev/null

    ln -s "$ZSH/custom/plugins/josh/.zshrc" "$HOME/.zshrc"

    if [ "$?" -gt 0 ]; then
        fail $0 "create symlink '$ZSH/custom/plugins/josh/.zshrc' -> '$HOME/.zshrc' failed"
        return 2
    fi
}
