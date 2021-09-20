#!/bin/sh

if [ "$JOSH" ] && [ -d "$JOSH" ]; then
    export SOURCE_ROOT="`realpath $JOSH`"

elif [ ! "$SOURCE_ROOT" ]; then
    if [ ! -f "`which -p realpath`" ]; then
        export SOURCE_ROOT="`dirname $0`/../../"
    else
        export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../../")
    fi

    if [ ! -d "$SOURCE_ROOT" ]; then
        echo " - fatal: source root $SOURCE_ROOT isn't correctly defined"
    else
        echo " + init from $SOURCE_ROOT"
        . $SOURCE_ROOT/run/init.sh
    fi
fi

if [ ! "$REAL" ]; then
    echo " - fatal: init failed, REAL empty"
    return 255
fi

if [ ! "$CONFIG_DIR" ]; then
    export CONFIG_DIR="$REAL/.config"
    if [ ! -d "$CONFIG_DIR" ]; then
        echo " - fatal: init failed, CONFIG_DIR must me created when call not in deploy context"
        return 255
    fi
fi

function backup_file() {
    if [ -f "$1" ]; then
        local dst="$1+`date "+%Y%m%d%H%M%S"`"
        if [ ! -f "$dst" ]; then
            echo " + backup: $1 -> $dst" && cp -fa "$1" "$dst"
        fi
        return $?
    fi
}

function copy_config() {
    local dst="$2"
    if [ -f "$dst" ] && [ ! "$JOSH_RENEW_CONFIGS" ]; then
        return 0
    fi

    local src="$1"
    if [ ! -f "$src" ]; then
        echo " - error: copy config failed, source \`$src\` not exists"
        return 1
    fi

    [ -f "$dst" ] && backup_file "$dst" && unlink "$dst"
    [ ! -d "`dirname $dst`" ] && mkdir -p "`dirname $dst`";

    echo " + ${3:-"copy: $src -> $dst"}" && cp -n "$src" "$dst"
    return $?
}

function config_git() {
    copy_config "$SOURCE_ROOT/usr/share/.gitignore" "$REAL/.gitignore"

    if [ ! "`git config --global core.pager | grep -P '^(delta)'`" ]; then
        backup_file "$REAL/.gitconfig" && \
        git config --global color.branch auto && \
        git config --global color.decorate auto && \
        git config --global color.diff auto && \
        git config --global color.grep auto && \
        git config --global color.interactive auto && \
        git config --global color.pager true && \
        git config --global color.showbranch auto && \
        git config --global color.status auto && \
        git config --global color.ui auto && \
        git config --global core.pager "delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate"
        # git config --global core.filemode false
        # git config --global core.safecrlf true
        # git config --global core.autocrlf true
    fi

    if [ ! "`git config --global sequence.editor`" ] && [ -f "`which -p interactive-rebase-tool`" ]; then
        backup_file "$REAL/.gitconfig" && \
        git config --global sequence.editor interactive-rebase-tool
    fi

    return 0
}

function nano_syntax_compile() {
    if [ ! -f "$REAL/.nanorc" ]; then
        # https://github.com/scopatz/nanorc

        if [ -d /usr/share/nano/ ]; then
            # linux
            find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $REAL/.nanorc

        elif [ -d /usr/local/share/nano/ ]; then
            # freebsd
            find /usr/local/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $REAL/.nanorc

        fi
        [ -f "$REAL/.nanorc" ] && echo " + nano syntax highlighting generated to $REAL/.nanorc ok"
    fi
    return 0
}

function zero_configuration() {
    local CONFIG_ROOT="$SOURCE_ROOT/usr/share"

    config_git
    nano_syntax_compile

    copy_config "$CONFIG_ROOT/cargo.toml" "$REAL/.cargo/config.toml"
    copy_config "$CONFIG_ROOT/micro.json" "$CONFIG_DIR/micro/settings.json"
    copy_config "$CONFIG_ROOT/nodeenv.conf" "$REAL/.nodeenvrc"
    copy_config "$CONFIG_ROOT/pip.conf" "$CONFIG_DIR/pip/pip.conf"
    copy_config "$CONFIG_ROOT/starship.toml" "$CONFIG_DIR/starship.toml"
    copy_config "$CONFIG_ROOT/mycli.conf" "$REAL/.myclirc"
    copy_config "$CONFIG_ROOT/pgcli.conf" "$CONFIG_DIR/pgcli/config"
}
