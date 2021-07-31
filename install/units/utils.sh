URL_FZF='https://github.com/junegunn/fzf.git'
URL_MICRO='https://getmic.ro'
URL_STARSHIP='https://starship.rs/install.sh'

EXEC_DIR="$TEMP_DIR/custom/bin"
[ ! -d $EXEC_DIR ] && mkdir -p $EXEC_DIR


# ——— starship prompt

if [ ! -f $EXEC_DIR/starship ]; then
    # static binary from official installer not found, ok
    if [ -f "`which starship`" ]; then
        echo " + use installed starship from `which starship`"
    else
        # and binary not found in system -> download
        echo " + deploy starship to $EXEC_DIR/starship"
        BIN_DIR=$EXEC_DIR FORCE=1 $SHELL -c "$(curl -fsSL $URL_STARSHIP)"
        [ $? -gt 0 ] && echo " - failed starship"
    fi
fi


# ——— fzf search

clone="`which git` clone --depth 1"
if [ ! -f $EXEC_DIR/fzf ]; then
    # $EXEC_DIR/fzf --version | head -n 1 | awk '{print $1}'
    echo " + deploy fzf to $EXEC_DIR/fzf"
    tempdir=`mktemp -d`
    rm -rf $tempdir
    $SHELL -c "$clone $URL_FZF $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $EXEC_DIR/fzf && rm -rf $tempdir"
    [ $? -gt 0 ] && echo " - failed fzf"
fi


# ——— micro editor

if [ ! -f $EXEC_DIR/micro ]; then
    # $EXEC_DIR/micro --version | head -n 1 | awk '{print $2}'
    echo " + deploy micro: $EXEC_DIR/micro"
    cd $EXEC_DIR && $SHELL -c "$HTTP_GET $URL_MICRO | $SHELL"
    [ $? -gt 0 ] && echo " + failed micro: $EXEC_DIR/micro"
    $SHELL -c "$EXEC_DIR/micro -plugin install fzf wc detectindent bounce editorconfig quickfix"
fi
