#!/bin/zsh

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$JOSH" ] && [ -z "$JOSH_BASE" ]; then
        source "$(dirname $0)/../boot.sh"
    fi

    CONFIG_DIR="$HOME/.config"
    [ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"

    if [ -n "$JOSH_DEST" ]; then
        BASE="$JOSH_BASE"
        if [ -z "$CONFIG_ROOT" ]; then
            info $0 "copy template configs to '$CONFIG_DIR'"
        fi
    else
        BASE="$JOSH"
    fi
fi

CONFIG_ROOT="$BASE/usr/share"

function __setup.cfg.backup_file {
    if [ -f "$1" ]; then
        local dst="$1+`date "+%Y%m%d%H%M%S"`"
        if [ ! -f "$dst" ]; then
            info $0 "backup $1 -> $dst"
            cp -fa "$1" "$dst"
        fi
        return $?
    fi
}

function __setup.cfg.copy_config {
    local cfg_modified count src_sum dst_sum

    local src="$1"
    if [ ! -f "$src" ]; then
        fail $0 "copy config failed, source '$src' doesn't exist"
        return 1
    fi

    local dst="$2"
    [ ! -d "$(fs.dirname $dst)" ] && mkdir -p "$(fs.dirname $dst)"

    if [ -f "$dst" ]; then
        src_sum="$(git hash-object "$src")" && dst_sum="$(git hash-object "$dst")"

        if [ "$?" -eq 0 ] && [[ "$src_sum" != "$dst_sum" ]]; then
            cfg_modified="$(fs.lm "$JOSH/usr/share" | tabulate -i 1)" || return "$?"

            local cwd="$PWD"
            builtin cd "$JOSH"
            local cfg_history=$(
                eval.cached "$cfg_modified" git \
                'rev-list --objects --all | grep usr/share | grep -Pv "usr/share$"')
            builtin cd "$PWD"

            count="$(echo $cfg_history | grep "$dst_sum" | wc -l)"
            if [ "$?" -eq 0 ] && [ "$count" -gt 0 ]; then
                __setup.cfg.backup_file "$dst"
                unlink "$dst" && cp -n "$src" "$dst" && \
                info $0 "$src -> $dst (because in commits history)"
                return 0
            fi
        fi

        if [ ! "$JOSH_FORCE_CONFIGS" ]; then
            return 0
        fi

        diff --ignore-blank-lines --strip-trailing-cr --brief "$src" "$dst" 1>/dev/null
        if [ "$?" -eq 0 ]; then
            return 0
        fi

        __setup.cfg.backup_file "$dst" && unlink "$dst"
    fi

    info $0 "$src -> $dst"
    cp -n "$src" "$dst"
    return "$?"
}

function __setup.cfg.config_git {
    __setup.cfg.copy_config "$BASE/usr/share/.gitignore" "$HOME/.gitignore"

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
        __setup.cfg.backup_file "$HOME/.gitconfig" && \
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
        __setup.cfg.backup_file "$HOME/.gitconfig" && \
        git config --global sequence.editor interactive-rebase-tool
    fi
}

function __setup.cfg.nano_syntax_compile {
    if [ ! -f "$HOME/.nanorc" ]; then
        # https://github.com/scopatz/nanorc

        if [ -d /usr/share/nano/ ]; then
            # linux
            find /usr/share/nano/ -iname "*.nanorc" -exec ec2ho include {} \; >> $HOME/.nanorc

        elif [ -d /usr/local/share/nano/ ]; then
            # freebsd
            find /usr/local/share/nano/ -iname "*.nanorc" -exec ec2ho include {} \; >> $HOME/.nanorc

        fi
        [ -f "$HOME/.nanorc" ] && info $0 "nano syntax highlight profile generated to $HOME/.nanorc"
    fi
    return 0
}

function __setup.cfg.zero_configuration {
    __setup.cfg.config_git
    __setup.cfg.nano_syntax_compile

    __setup.cfg.copy_config "$CONFIG_ROOT/cargo.toml"    "$HOME/.cargo/config.toml"
    __setup.cfg.copy_config "$CONFIG_ROOT/lsd.yaml"      "$CONFIG_DIR/lsd/config.yaml"
    __setup.cfg.copy_config "$CONFIG_ROOT/mycli.conf"    "$HOME/.myclirc"
    __setup.cfg.copy_config "$CONFIG_ROOT/nodeenv.conf"  "$HOME/.nodeenvrc"
    __setup.cfg.copy_config "$CONFIG_ROOT/ondir.rc"      "$HOME/.ondirrc"
    __setup.cfg.copy_config "$CONFIG_ROOT/pgcli.conf"    "$CONFIG_DIR/pgcli/config"
    __setup.cfg.copy_config "$CONFIG_ROOT/pip.conf"      "$CONFIG_DIR/pip/pip.conf"
    __setup.cfg.copy_config "$CONFIG_ROOT/tmux.conf"     "$HOME/.tmux.conf"
    __setup.cfg.copy_config "$CONFIG_ROOT/logout.zsh"    "$HOME/.zlogout"
}
