#!/bin/zsh


export CONFIG_DIR="$HOME/.config"
[ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"


function cfg.backup {
    if [ -e "$1" ]; then
        local dst="$1.$(date "+%Y%m%d%H%M%S").bak"
        if [ ! -f "$dst" ]; then
            info $0 "backup $1 -> $dst"
            cp -fa "$1" "$dst"
        fi
        return $?
    fi
}

function cfg.copy {
    local cfg_modified count src_sum dst_sum

    local src="$1"
    if [ ! -e "$src" ]; then
        fail $0 "copy config failed, source '$src' doesn't exist"
        return 1
    fi

    local dst="$2"
    [ ! -d "$(fs.dirname $dst)" ] && mkdir -p "$(fs.dirname $dst)"

    if [ -L "$dst" ]; then
        warn $0 "$dst is symlink to $(fs.realpath "$dst"), unlink"
        cfg.backup "$dst" && unlink "$dst"

    elif [ -e "$dst" ]; then
        src_sum="$(git hash-object "$src")" && dst_sum="$(git hash-object "$dst")"

        if [ "$?" -eq 0 ] && [[ "$src_sum" != "$dst_sum" ]]; then
            cfg_modified="$(fs.lm "$ASH/usr/share" | grep -Po '\d+.\d+')" || return "$?"

            local cwd="$PWD"
            builtin cd "$ASH"
            local cfg_history=$(
                eval.cached "$cfg_modified" git \
                'rev-list --objects --all | grep usr/share | grep -Pv "usr/share$"')
            builtin cd "$PWD"

            count="$(echo $cfg_history | grep "$dst_sum" | wc -l)"
            if [ "$?" -eq 0 ] && [ "$count" -gt 0 ]; then
                cfg.backup "$dst"
                unlink "$dst" && cp -n "$src" "$dst" && \
                info $0 "$src -> $dst (because in commits history)"
                return 0
            fi
        fi

        diff --ignore-blank-lines --strip-trailing-cr --brief "$src" "$dst" 1>/dev/null
        if [ "$?" -eq 0 ]; then
            return 0
        fi

        if [ ! "$ASH_FORCE_CONFIGS" ]; then
            return 0
        fi

        cfg.backup "$dst" && unlink "$dst"
    fi

    info $0 "$src -> $dst"
    cp -n "$src" "$dst"
    return "$?"
}

function cfg.git_configure {
    if [ ! -x "$ASH" ]; then
        term $0 "something went wrong, ASH path empty"
        return 1
    fi

    cfg.copy "$ASH/usr/share/.gitignore" "$HOME/.gitignore" || return "$?"

    if [ -f "$HOME/.gitignore" ] && [ ! -e "$HOME/.agignore" ] && [ ! -L "$HOME/.agignore" ]; then
        ln -s "$HOME/.gitignore" "$HOME/.agignore"
    fi

    if [ -f "$HOME/.gitignore" ] && [ ! -e "$HOME/.ignore" ] && [ ! -L "$HOME/.ignore" ]; then
        ln -s "$HOME/.gitignore" "$HOME/.ignore"
    fi

    function set_style() {
        git config --global core.pager "delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-header-decoration-style='' --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-right-format='{np:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --merge-conflict-ours-diff-header-decoration-style='' --merge-conflict-ours-diff-header-style='dim cyan' --merge-conflict-theirs-diff-header-decoration-style='' --merge-conflict-theirs-diff-header-style='dim cyan' --line-numbers --navigate --diff-so-fancy --line-fill-method='spaces' --pager less"
    }

    if [ -z "`git config --global core.pager | grep -P '^(delta)'`" ]; then
        cfg.backup "$HOME/.gitconfig" && \
        git config --global color.branch auto && \
        git config --global color.decorate auto && \
        git config --global color.diff auto && \
        git config --global color.grep auto && \
        git config --global color.interactive auto && \
        git config --global color.pager true && \
        git config --global color.showbranch auto && \
        git config --global color.status auto && \
        git config --global color.ui auto && \
        set_style
    fi

    if [ -n "$(git config --global core.pager | grep 'hunk-style normal')" ]; then
        set_style
    fi

    if [ -z "$(git config --global sequence.editor)" ] && [ -x "$(which interactive-rebase-tool)" ]; then
        cfg.backup "$HOME/.gitconfig" && \
        git config --global sequence.editor interactive-rebase-tool
    fi
}

function cfg.nano_syntax {
    if [ ! -f "$HOME/.nanorc" ]; then
        # https://github.com/scopatz/nanorc

        if [ -d /usr/share/nano/ ]; then
            # linux
            find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $HOME/.nanorc

        elif [ -d /usr/local/share/nano/ ]; then
            # freebsd
            find /usr/local/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $HOME/.nanorc

        fi
        [ -f "$HOME/.nanorc" ] && info $0 "nano syntax highlight profile generated to $HOME/.nanorc"
    fi
}

function cfg.install {
    if [ ! -x "$ASH" ]; then
        term $0 "something went wrong, ASH path empty"
        return 1
    fi
    local root="$ASH/usr/share"

    cfg.git_configure
    cfg.nano_syntax

    cfg.copy "$ASH/.zshrc"          "$HOME/.zshrc"
    cfg.copy "$root/cargo.toml"     "$HOME/.cargo/config.toml"
    cfg.copy "$root/gdb.conf"       "$HOME/.gdbinit"
    cfg.copy "$root/htop.rc"        "$CONFIG_DIR/htop/htoprc"
    cfg.copy "$root/logout.zsh"     "$HOME/.zlogout"
    cfg.copy "$root/lsd.yaml"       "$CONFIG_DIR/lsd/config.yaml"
    cfg.copy "$root/lsd_theme.yaml" "$CONFIG_DIR/lsd/colors.yaml"
    cfg.copy "$root/mycli.conf"     "$HOME/.myclirc"
    cfg.copy "$root/nodeenv.conf"   "$HOME/.nodeenvrc"
    cfg.copy "$root/pgcli.conf"     "$CONFIG_DIR/pgcli/config"
    cfg.copy "$root/pip.conf"       "$CONFIG_DIR/pip/pip.conf"
    cfg.copy "$root/tmux.conf"      "$HOME/.tmux.conf"
}
