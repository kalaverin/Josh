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
if [ ! "$HTTP_GET" ]; then
    echo " - fatal: init failed, HTTP_GET empty"
    return 255
fi
if [ "$MERGE_DIR" ]; then
    BINARY_DEST="$MERGE_DIR/custom/bin"
else
    BINARY_DEST="$ZSH/custom/bin"
    if [ ! -d "$BINARY_DEST" ]; then
        echo " - fatal: init failed, BINARY_DEST must me created when call not in deploy context"
        return 255
    fi
fi


# ——— starship prompt

function deploy_starship() {
    url='https://starship.rs/install.sh'
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ ! -f "$BINARY_DEST/starship" ]; then
        # static binary from official installer not found, ok
        if [ -f "`which starship`" ]; then
            echo " + use installed starship from `which starship`"
        else
            # and binary not found in system -> download
            echo " + deploy starship to $BINARY_DEST/starship"
            $SHELL -c "$HTTP_GET $url" | BIN_DIR=$BINARY_DEST FORCE=1 $SHELL
            [ $? -gt 0 ] && echo " - failed starship"
        fi
    fi
    . $SOURCE_ROOT/run/units/configs.sh && copy_starship
    return 0
}


# ——— fzf search

function compile_fzf() {
    url='https://github.com/junegunn/fzf.git'
    clone="`which git` clone --depth 1"
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ -f "$BINARY_DEST/fzf" ]; then
        [ -f "$BINARY_DEST/fzf.bak" ] && rm "$BINARY_DEST/fzf.bak"

        local found="`find $BINARY_DEST/fzf -mmin +129600 2>/dev/null | grep fzf`"
        if [ "$found" ]; then
            mv "$BINARY_DEST/fzf" "$BINARY_DEST/fzf.bak"
        fi
    fi

    if [ ! -f "$BINARY_DEST/fzf" ]; then
        echo " + deploy fzf to $BINARY_DEST/fzf"

        local tempdir="$(dirname `mktemp -duq`)/fzf"
        [ -d "$tempdir" ] && rm -rf "$tempdir"

        $SHELL -c "$clone $url $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $BINARY_DEST/fzf && rm -rf $tempdir"
        [ $? -gt 0 ] && echo " - failed fzf"
    fi

    if [ -f "$BINARY_DEST/fzf.bak" ]; then
        if [ -f "$BINARY_DEST/fzf" ]; then
            rm "$BINARY_DEST/fzf.bak"
        else
            mv "$BINARY_DEST/fzf.bak" "$BINARY_DEST/fzf"
        fi
    fi
    return 0
}


# ——— micro editor

function deploy_micro() {
    url='https://getmic.ro'
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ ! -f "$BINARY_DEST/micro" ]; then
        # $BINARY_DEST/micro --version | head -n 1 | awk '{print $2}'
        echo " + deploy micro: $BINARY_DEST/micro"
        cd "$BINARY_DEST" && $SHELL -c "$HTTP_GET $url | $SHELL"
        [ $? -gt 0 ] && echo " + failed micro: $BINARY_DEST/micro"
        $SHELL -c "$BINARY_DEST/micro -plugin install fzf wc detectindent bounce editorconfig quickfix"
    fi
    . $SOURCE_ROOT/run/units/configs.sh && copy_micro
    return 0
}


function deploy_binaries() {
    compile_fzf && \
    deploy_micro && \
    deploy_starship && \
    return "$?"
}
