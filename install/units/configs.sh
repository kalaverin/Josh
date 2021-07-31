[ ! -d $CONF_DIR ] && mkdir -p $CONF_DIR

if [ ! -f "$CONF_DIR/starship.toml" ]; then
    cp $INSTALL_ROOT/configs/starship.toml $CONF_DIR/starship.toml
    echo " + starship config: $CONF_DIR/starship.toml"
fi

if [ ! -f "$CONF_DIR/micro/settings.json" ]; then
    [ ! -d $CONF_DIR/micro/ ] && mkdir -p $CONF_DIR/micro
    cp $INSTALL_ROOT/configs/micro.json $CONF_DIR/micro/settings.json
    echo " + micro editor config: $CONF_DIR/micro/settings.json"
fi
