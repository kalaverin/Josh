#!/bin/zsh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    [ -z "$HTTP_GET" ] && source "$(dirname $0)/../boot.sh"
    [ -z "$OMZ_PLUGIN_DIR" ] && source "$(fs_dirname $0)/oh-my-zsh.sh"

    BINARY_DEST="$HOME/.local/bin"
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ -n "$JOSH_DEST" ]; then
        echo " + compile binaries to \`$BINARY_DEST\`"
        BASE="$JOSH_BASE"
    else
        BASE="$JOSH"
    fi
fi

# ——— ondir events runner

function compile_ondir {
    if [ -x "$BINARY_DEST/ondir" ]; then
        return 0
    fi

    if [ -z "$OMZ_PLUGIN_DIR" ]; then
        printf " -- info ($0): plugins dir isn't set\n" >&2
        return 1

    elif [ ! -d "$OMZ_PLUGIN_DIR/ondir" ]; then
        git clone --depth 1 "https://github.com/alecthomas/ondir.git" "$OMZ_PLUGIN_DIR/ondir"
    fi

    local cwd="$PWD"
    printf " -- info ($0): compile ondir in '$OMZ_PLUGIN_DIR' -> '$BINARY_DEST'\n" >&2
    builtin cd "$OMZ_PLUGIN_DIR/ondir" && make clean && make && mv ondir "$BINARY_DEST/ondir" && make clean

    local retval="$?"
    [ "$retval" -gt 0 ] && printf " ** fail ($0): something went wrong\n" >&2

    builtin cd "$cwd"
    return "$retval"
}

# ——— fzf search

function compile_fzf {
    local url='https://github.com/junegunn/fzf.git'
    local clone="$(which git) clone --depth 1"

    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"
    if [ ! -d "$BINARY_DEST" ]; then
        printf " ** fail ($0): binary dir doesn't exist, BINARY_DEST '$BINARY_DEST'\n" >&2
        return 1

    elif [ -x "$BINARY_DEST/fzf" ]; then
        [ -f "$BINARY_DEST/fzf.bak" ] && rm "$BINARY_DEST/fzf.bak"

        if [ "$(find $BINARY_DEST/fzf -mmin +129600 2>/dev/null | grep fzf)" ]; then
            mv "$BINARY_DEST/fzf" "$BINARY_DEST/fzf.bak"
        fi
    fi

    if [ ! -f "$BINARY_DEST/fzf" ]; then
        printf " -- info ($0): deploy fzf to $BINARY_DEST/fzf\n" >&2

        local tempdir="$(fs_dirname `mktemp -duq`)/fzf"
        [ -d "$tempdir" ] && rm -rf "$tempdir"

        $SHELL -c "$clone $url $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $BINARY_DEST/fzf && rm -rf $tempdir"
        [ "$?" -gt 0 ] && printf " ** fail ($0): something went wrong\n" >&2
    fi

    if [ -f "$BINARY_DEST/fzf.bak" ]; then
        if [ -f "$BINARY_DEST/fzf" ]; then
            rm "$BINARY_DEST/fzf.bak"
        else
            mv "$BINARY_DEST/fzf.bak" "$BINARY_DEST/fzf"
        fi
    fi
}

# ——— micro editor

function deploy_micro {
    local url='https://getmic.ro'

    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"
    if [ ! -d "$BINARY_DEST" ]; then
        printf " ** fail ($0): binary dir doesn't exist, BINARY_DEST '$BINARY_DEST'\n" >&2
        return 1

    elif [ ! -x "$BINARY_DEST/micro" ]; then
        # $BINARY_DEST/micro --version | head -n 1 | awk '{print $2}'

        local cwd="$PWD"
        printf " -- info ($0): deploy micro: $BINARY_DEST/micro\n" >&2
        builtin cd "$BINARY_DEST" && $SHELL -c "$HTTP_GET $url | $SHELL"

        [ "$?" -gt 0 ] && printf " ** fail ($0): something went wrong\n" >&2
        $SHELL -c "$BINARY_DEST/micro -plugin install fzf wc detectindent bounce editorconfig quickfix"
        builtin cd "$cwd"
    fi
    source "$BASE/run/units/configs.sh"
    copy_config "$CONFIG_ROOT/micro_config.json" "$CONFIG_DIR/micro/settings.json"
    copy_config "$CONFIG_ROOT/micro_binds.json" "$CONFIG_DIR/micro/bindings.json"
}

# ——— tmux plugin manager

function deploy_tmux_plugins {
    local TMUX_DEST="$HOME/.tmux/plugins"

    [ ! -d "$TMUX_DEST" ] && mkdir -p "$TMUX_DEST"
    if [ ! -d "$TMUX_DEST" ]; then
        printf " ** fail ($0): binary dir isn't exist, TMUX_DEST '$TMUX_DEST'\n" >&2
        return 1

    elif [ ! -x "$TMUX_DEST/tpm" ]; then
        git clone --depth 1 "https://github.com/tmux-plugins/tpm" "$TMUX_DEST/tpm"
        [ "$?" -gt 0 ] && return 2
    fi

    if [ -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
        export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    fi

    if [ -x "$(which bash)" ]; then
        bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    else
        printf " ++ warn ($0): it's funny, but tmux plugin manager required bash for installation bootstrap\n" >&2
    fi
}


function link_fpp {
    local src="$OMZ_PLUGIN_DIR/fpp"

    if [ -z "$OMZ_PLUGIN_DIR" ]; then
        printf " ** fail ($0): plugins dir isn't set\n" >&2
        return 1

    elif [ ! -d "$src" ]; then
        printf " -- info ($0): deploy to '$OMZ_PLUGIN_DIR'\n" >&2
        git clone --depth 1 "https://github.com/facebook/PathPicker.git" "$src"
        local retval="$?"
    fi

    if [ -x "$src/fpp" ]; then
        local dst="$(shortcut "$src/fpp")"
        if [ -z "$dst" ]; then
            local retval="127"
        else
            printf " -- info ($0): fpp -> $dst\n" >&2
        fi
    fi

    [ "$retval" -gt 0 ] && printf " ** fail ($0): something went wrong\n" >&2
    return "$retval"
}

function link_git_tools {
    local src="$OMZ_PLUGIN_DIR/git-tools"

    if [ -z "$OMZ_PLUGIN_DIR" ]; then
        printf " ** fail ($0): plugins dir isn't set\n" >&2
        return 1

    elif [ ! -d "$src" ]; then
        printf " -- info ($0): deploy '$OMZ_PLUGIN_DIR'\n" >&2
        git clone --depth 1 "https://github.com/MestreLion/git-tools.git" "$src"
        local retval="$?"
    fi

    if [ -d "$src" ]; then
        find "$src" -maxdepth 1 -type f -executable | while read exe
        do
            if [ -x "$exe" ]; then
                local dst="$(shortcut "$exe")"
                if [ -z "$dst" ]; then
                    local retval="127"
                else
                    printf " -- info ($0): '$(fs_basename "$dst")' -> '$dst'\n" >&2
                fi
            fi
        done
    fi

    [ "$retval" -gt 0 ] && printf " ** fail ($0): something went wrong\n" >&2
    return "$retval"
}

function deploy_binaries {
    compile_fzf && \
    deploy_micro && \
    deploy_tmux_plugins && \
    compile_ondir && \
    link_fpp && \
    link_git_tools || return "$?"
}
