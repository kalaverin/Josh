#!/bin/sh

if [ ! "$CONFIG_DIR" ]; then
    echo " - fatal: init failed, CONFIG_DIR empty"
    exit 255
fi
if [ ! "$SOURCE_ROOT" ]; then
    echo " - fatal: init failed, SOURCE_ROOT empty"
    exit 255
fi

[ ! -d "$CONFIG_DIR" ] && mkdir -p $CONFIG_DIR

function config_starship() {
    if [ ! -f "$CONFIG_DIR/starship.toml" ]; then
        cp $SOURCE_ROOT/configs/starship.toml $CONFIG_DIR/starship.toml
        echo " + copy starship example config: $CONFIG_DIR/starship.toml"
    fi
}

function config_micro() {
    if [ ! -f "$CONFIG_DIR/micro/settings.json" ]; then
        [ ! -d "$CONFIG_DIR/micro/" ] && mkdir -p "$CONFIG_DIR/micro"
        cp "$SOURCE_ROOT/configs/micro.json" "$CONFIG_DIR/micro/settings.json"
        echo " + copy micro editor example config: $CONFIG_DIR/micro/settings.json"
    fi
}
