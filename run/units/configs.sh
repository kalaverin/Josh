#!/bin/sh

if [ ! "$SOURCE_ROOT" ]; then
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../../")
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/run/init.sh
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

function copy_starship() {
    local dst="$CONFIG_DIR/starship.toml"
    [ ! -d "`dirname $dst`" ] && mkdir -p "`dirname $dst`"; [ -f "$dst" ] && return 0
    echo " + copy starship example config: $dst" && \
    cp -n "$SOURCE_ROOT/usr/share/starship.toml" "$dst"
    return $?
}

function copy_micro() {
    local dst="$CONFIG_DIR/micro/settings.json"
    [ ! -d "`dirname $dst`" ] && mkdir -p "`dirname $dst`"; [ -f "$dst" ] && return 0
    echo " + copy micro editor example config: $dst" && \
    cp -n "$SOURCE_ROOT/usr/share/micro.json" "$dst"
    return $?
}

function copy_pip() {
    local dst="$CONFIG_DIR/pip/pip.conf"
    [ ! -d "`dirname $dst`" ] && mkdir -p "`dirname $dst`"; [ -f "$dst" ] && return 0
    echo " + copy pip example config: $dst" && \
    cp -n "$SOURCE_ROOT/usr/share/pip.conf" "$dst"
    return $?
}

function copy_gitignore() {
    local dst="$REAL/.gitignore"
    [ -f "$dst" ] && return 0
    echo " + copy $dst template" && \
    cp -n "$SOURCE_ROOT/usr/share/.gitignore" "$dst"
    return $?
}

function config_git() {
    copy_gitignore
    if [ ! "`git config --global core.pager | grep -P '^(delta)'`" ]; then
        git config --global color.branch auto
        git config --global color.decorate auto
        git config --global color.diff auto
        git config --global color.grep auto
        git config --global color.interactive auto
        git config --global color.pager true
        git config --global color.showbranch auto
        git config --global color.status auto
        git config --global color.ui auto
        git config --global core.pager "delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate"
        # git config --global core.filemode false
        # git config --global core.safecrlf true
        # git config --global core.autocrlf true
    fi
    return 0
}

function nano_syntax_compile() {
    if [ ! -f "$REAL/.nanorc" ]; then
        # https://github.com/scopatz/nanorc
        if [ -d /usr/local/share/nano/ ]; then
            find /usr/local/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $REAL/.nanorc
        fi
        if [ -d /usr/share/nano/ ]; then
            find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $REAL/.nanorc
        fi
        if [ -f "$REAL/.nanorc" ]; then
            echo " + nano config $REAL/.nanorc generated"
        fi
    fi
    return 0
}

function zero_configuration() {
    copy_starship
    copy_micro
    copy_pip
    config_git
    nano_syntax_compile
}
