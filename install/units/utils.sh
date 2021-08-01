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
    return 0
}


# ——— fzf search

function deploy_fzf() {
    url='https://github.com/junegunn/fzf.git'
    clone="`which git` clone --depth 1"
    [ ! -d "$BINARY_DEST" ] && mkdir -p "$BINARY_DEST"

    if [ ! -f "$BINARY_DEST/fzf" ]; then
        # $BINARY_DEST/fzf --version | head -n 1 | awk '{print $1}'
        echo " + deploy fzf to $BINARY_DEST/fzf"
        tempdir="`mktemp -d`"
        rm -rf "$tempdir"
        $SHELL -c "$clone $url $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $BINARY_DEST/fzf && rm -rf $tempdir"
        [ $? -gt 0 ] && echo " - failed fzf"
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
    return 0
}


# ——— fresh pip for python 3

function deploy_pip() {
    local py="`which python3`"
    if [ -f "$py" ]; then
        local pip="/tmp/get-pip.py"
        $SHELL -c "$HTTP_GET https://bootstrap.pypa.io/get-pip.py > $pip" && \
        PIP_REQUIRE_VIRTUALENV=false python3 $pip "pip<=20.3.4" "setuptools" "wheel"
        [ -f "$pip" ] && unlink "$pip"
    else
        echo " - require python >=3.6!"
    fi
    return 0
}


# ——— httpie client

function deploy_httpie() {
    local pip="$REAL/.local/bin/pip"
    if [ ! -f "$pip" ]; then
        deploy_pip
    fi
    if [ ! -f "$pip" ]; then
        echo " - pip required python >=3.6!"
    else
        PIP_REQUIRE_VIRTUALENV=false pip install --user --upgrade httpie
    fi
    return 0
}
