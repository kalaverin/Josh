#!/bin/sh

if [ ! "$SOURCE_ROOT" ]; then
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../../")
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/install/init.sh
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

function config_starship() {
    [ ! -d "$CONFIG_DIR" ] && mkdir -p $CONFIG_DIR
    if [ ! -f "$CONFIG_DIR/starship.toml" ]; then
        cp $SOURCE_ROOT/configs/starship.toml $CONFIG_DIR/starship.toml
        echo " + copy starship example config: $CONFIG_DIR/starship.toml"
    fi
    return 0
}

function config_micro() {
    [ ! -d "$CONFIG_DIR" ] && mkdir -p $CONFIG_DIR
    if [ ! -f "$CONFIG_DIR/micro/settings.json" ]; then
        [ ! -d "$CONFIG_DIR/micro/" ] && mkdir -p "$CONFIG_DIR/micro"
        cp "$SOURCE_ROOT/configs/micro.json" "$CONFIG_DIR/micro/settings.json"
        echo " + copy micro editor example config: $CONFIG_DIR/micro/settings.json"
    fi
    return 0
}

function config_syncat() {
    [ ! -d "$CONFIG_DIR" ] && mkdir -p $CONFIG_DIR
    if [ ! -f "$CONFIG_DIR/syncat/languages.toml" ]; then
        [ ! -d "$CONFIG_DIR/syncat/" ] && mkdir -p "$CONFIG_DIR/syncat"
        cp "$SOURCE_ROOT/configs/syncat.toml" "$CONFIG_DIR/syncat/languages.toml"
        echo " + copy syncat viewer example config: $CONFIG_DIR/syncat/languages.toml"
    fi
    if [ ! -d "$CONFIG_DIR/syncat/languages" ]; then
        syncat install
    fi
    return 0
}

function config_git() {
    git config --global color.ui auto
    git config --global color.branch auto
    git config --global color.diff auto
    git config --global color.interactive auto
    git config --global color.status auto
    git config --global color.grep auto
    git config --global color.pager true
    git config --global color.decorate auto
    git config --global color.showbranch auto
    git config --global core.pager "delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style normal --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers-minus-style='#aa2222' --line-numbers-zero-style='#505055' --line-numbers-plus-style='#229922' --line-numbers --navigate"
    return 0
}


function nano_syntax() {
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


function grep_ignore() {
    if [ ! -f "$REAL/.ignore" ]; then
        cp $SOURCE_ROOT/configs/grep.ignore "$REAL/.ignore"
        echo " + copy grep ignore $REAL/.ignore template"
    fi
    return 0
}
