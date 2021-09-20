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
if [ ! "$HTTP_GET" ]; then
    echo " - fatal: init failed, HTTP_GET empty"
    return 255
fi

if [ "$MERGE_DIR" ]; then
    BINARY_DEST="$MERGE_DIR/custom/bin"
else
    BINARY_DEST="$ZSH/custom/bin"
    if [ ! -d "$ZSH/custom" ]; then
        echo " - fatal: init failed, \$ZSH/custom=\`$ZSH/custom\` isn't found"
        return 255
    fi
fi


# ——— fzf search

function compile_fzf() {
    url='https://github.com/junegunn/fzf.git'
    clone="`which git` clone --depth 1"
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ -f "$BINARY_DEST/fzf" ]; then
        [ -f "$BINARY_DEST/fzf.bak" ] && rm "$BINARY_DEST/fzf.bak"

        if [ "`find $BINARY_DEST/fzf -mmin +129600 2>/dev/null | grep fzf`" ]; then
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
    . $SOURCE_ROOT/run/units/configs.sh && copy_config "$CONFIG_ROOT/micro.json" "$CONFIG_DIR/micro/settings.json"
    return 0
}


function deploy_binaries() {
    compile_fzf && \
    deploy_micro && \
    return "$?"
}
