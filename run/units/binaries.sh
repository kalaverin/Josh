#!/bin/zsh


export LOCAL_BIN="$HOME/.local/bin"
[ ! -d "$LOCAL_BIN" ] && mkdir -p "$LOCAL_BIN"
[ -z "$PLUGINS_ROOT" ] && source "$(fs.dirname $0)/oh-my-zsh.sh"

# ——— fzf search

function bin.compile_fzf {
    local url='https://github.com/junegunn/fzf.git'
    local clone="$(which git) clone --depth 1"

    [ ! -d "$LOCAL_BIN" ] && mkdir -p "$LOCAL_BIN"
    if [ ! -d "$LOCAL_BIN" ]; then
        fail $0 "binary dir doesn't exist, LOCAL_BIN '$LOCAL_BIN'"
        return 1

    elif [ -x "$LOCAL_BIN/fzf" ]; then
        [ -f "$LOCAL_BIN/fzf.bak" ] && rm -f "$LOCAL_BIN/fzf.bak"

        if [ "$(find $LOCAL_BIN/fzf -mmin +43200 2>/dev/null | grep fzf)" ]; then
            mv "$LOCAL_BIN/fzf" "$LOCAL_BIN/fzf.bak"
        fi
    fi

    if [ ! -f "$LOCAL_BIN/fzf" ]; then
        info $0 "deploy fzf to $LOCAL_BIN/fzf"

        local tempdir="$(fs.dirname `mktemp -duq`)/fzf"
        [ -d "$tempdir" ] && rm -rf "$tempdir"

        $SHELL -c "$clone $url $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $LOCAL_BIN/fzf && rm -rf $tempdir"

        if [ "$?" -gt 0 ]; then
            fail $0 "something went wrong"
        elif [ -x "$LOCAL_BIN/fzf" ]; then
            fs.link "$LOCAL_BIN/fzf" >/dev/null
        fi
    fi

    if [ -f "$LOCAL_BIN/fzf.bak" ]; then
        if [ -x "$LOCAL_BIN/fzf" ]; then
            rm -f "$LOCAL_BIN/fzf.bak"
        else
            mv "$LOCAL_BIN/fzf.bak" "$LOCAL_BIN/fzf"
        fi
    fi
    chmod a+x "$LOCAL_BIN/fzf"
    fs.link "$LOCAL_BIN/fzf" >/dev/null
}

# ——— micro editor

function bin.deploy_micro {

    if [ -x "$commands/micro" ]; then
        micro -plugin install fzf wc detectindent bounce editorconfig quickfix
        fs.link "$commands/micro" >/dev/null
    else
        warn $0 "micro isn't found"
    fi

    source "$ASH/run/units/configs.sh"
    cfg.copy "$ASH/usr/share/micro_config.json" "$CONFIG_DIR/micro/settings.json"
    cfg.copy "$ASH/usr/share/micro_binds.json" "$CONFIG_DIR/micro/bindings.json"
}

# ——— direnv

function bin.deploy_direnv {

    if [ -x "$commands/direnv" ]; then
        fs.link "$commands/direnv" >/dev/null
    else
        warn $0 "direnv isn't found"
    fi

    source "$ASH/run/units/configs.sh"
    cfg.copy "$ASH/usr/share/direnv.rc" "$CONFIG_DIR/direnv/direnvrc"
}

# ——— rye all-in-one python packaging tool

function bin.deploy_rye {
    local bin="$HOME/.rye/shims/rye"
    local url='https://rye-up.com/get'

    if [ -z "$HTTP_GET" ]; then
        fail $0 "HTTP_GET isn't set"
        return 1

    elif [ -f "$bin" ] && [ -x "$bin" ]; then
        if [ "$(find "$bin" -mmin +43200 2>/dev/null | grep rye)" ]; then
            $bin self update

            if [ -x "$bin" ]; then
                fs.link "$bin"
                mkdir "$ZSH_CUSTOM/plugins/rye"
                $bin self completion -s zsh > "$ZSH_CUSTOM/plugins/rye/_rye"
            fi
        fi
    fi

    if [ ! -x "$bin" ]; then
        local cwd="$PWD"
        info $0 "deploy rye: $bin"

        $SHELL -c "$HTTP_GET $url | RYE_INSTALL_OPTION="--yes" RYE_NO_AUTO_INSTALL=1 bash"
        [ "$?" -gt 0 ] && fail $0 "something went wrong"
        builtin cd "$cwd"

        if [ -x "$bin" ]; then
            fs.link "$bin"
            mkdir "$ZSH_CUSTOM/plugins/rye"
            $bin self completion -s zsh > "$ZSH_CUSTOM/plugins/rye/_rye"
        fi
    fi
}

# ——— tmux plugin manager

function bin.deploy_tmux_plugins {
    local TMUX_DEST="$HOME/.tmux/plugins"

    [ ! -d "$TMUX_DEST" ] && mkdir -p "$TMUX_DEST"
    if [ ! -d "$TMUX_DEST" ]; then
        fail $0 "binary dir isn't exist, TMUX_DEST '$TMUX_DEST'"
        return 1

    elif [ ! -x "$TMUX_DEST/tpm" ]; then
        git clone --depth 1 "https://github.com/tmux-plugins/tpm" "$TMUX_DEST/tpm"
        [ "$?" -gt 0 ] && return 2
    fi

    if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
        export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    fi

    if [ -n "$PS1" ] && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
        if [ -x "$(which bash)" ]; then
            timeout -s 9 5.0 bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
        else
            warn $0 "it's funny, but tmux plugin manager required bash for installation bootstrap"
        fi
    fi
}

function bin.link_fpp {
    local src="$PLUGINS_ROOT/fpp"

    if [ -z "$PLUGINS_ROOT" ]; then
        fail $0 "plugins dir isn't set"
        return 1

    elif [ ! -d "$src" ]; then
        info $0 "deploy to '$PLUGINS_ROOT'"
        git clone --depth 1 "https://github.com/facebook/PathPicker.git" "$src"
        local retval="$?"
    fi

    if [ -x "$src/fpp" ] && [ ! -x "$ASH/bin/fpp" ]; then
        local dst="$(fs.link "$src/fpp")"
        if [ -z "$dst" ]; then
            local retval="127"
        else
            info $0 "fpp -> $dst"
        fi
    fi

    [ "$retval" -gt 0 ] && fail $0 "something went wrong"
    return "$retval"
}

function bin.link_git_tools {
    local find
    local src="$PLUGINS_ROOT/git-tools"

    if [ -z "$PLUGINS_ROOT" ]; then
        fail $0 "plugins dir isn't set"
        return 1

    elif [ ! -d "$src" ]; then
        info $0 "deploy '$PLUGINS_ROOT'"
        git clone --depth 1 "https://github.com/MestreLion/git-tools.git" "$src"
        local retval="$?"
    fi

    if [ -d "$src" ]; then
        find="$(which gfind)"; [ ! -x "$find" ] && find="$(which find)"
        $find "$src" -maxdepth 1 -type f -executable | while read exe
        do
            if [ -x "$exe" ] && [ ! -x "$ASH/bin/$(fs.basename "$exe")" ]; then
                local dst="$(fs.link "$exe")"
                if [ -z "$dst" ]; then
                    local retval="127"
                else
                    info $0 "'$(fs.basename "$dst")' -> '$dst'"
                fi
            fi
        done
    fi

    [ "$retval" -gt 0 ] && fail $0 "something went wrong"
    return "$retval"
}

function bin.install {
    if [ ! -x "$ASH" ]; then
        term $0 "something went wrong, ASH path empty"
        return 1
    fi

    bin.compile_fzf
    bin.deploy_direnv
    bin.deploy_micro
    bin.deploy_tmux_plugins
    bin.link_fpp
    bin.link_git_tools
}
