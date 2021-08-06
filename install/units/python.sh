#!/bin/sh

PIP_REQ_PACKAGES=(
    httpie
    pip-chill
    pipdeptree
    virtualenv
)

PIP_OPT_PACKAGES=(
)

function set_defaults() {
    if [ ! "$REAL" ]; then
        export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
        echo " + init from $SOURCE_ROOT"
        . $SOURCE_ROOT/install/init.sh

        if [ ! "$REAL" ]; then
            echo " - fatal: init failed"
            return 255
        fi
    fi
    if [ ! "$HTTP_GET" ]; then
        echo " - fatal: init failed, HTTP_GET empty"
        return 255
    fi
    return 0
}

function pip_init() {
    local py="`which python3`"
    if [ ! -f "$py" ]; then
        echo " - require python >=3.6!"
        return 1
    fi

    set_defaults
    export PIP_EXE="$REAL/.local/bin/pip"

    url="https://bootstrap.pypa.io/get-pip.py"
    if [ ! -f "$PIP_EXE" ]; then
        local pip_bootstrap="/tmp/get-pip.py"
        $SHELL -c "$HTTP_GET $url > $pip_bootstrap" && \
        PIP_REQUIRE_VIRTUALENV=false python3 $pip_bootstrap "pip<=20.3.4" "setuptools" "wheel"
        [ -f "$pip_bootstrap" ] && unlink "$pip_bootstrap"
        if [ $? -gt 0 ]; then
            echo " - fatal: pip deploy failed!"
            return 1
        fi
        if [ ! -f "$PIP_EXE" ]; then
            echo " - fatal: pip isn't installed ($PIP_EXE)"
            return 255
        fi
    fi
    return 0
}

function pip_deploy() {
    pip_init || return $?
    if [ ! -f "$PIP_EXE" ]; then
        echo " - fatal: cargo exe $PIP_EXE isn't found!"
        return 1
    fi
    for pkg in $@; do
        $PIP_EXE install --upgrade $pkg
    done
    return 0
}


function pip_extras() {
    pip_deploy $PIP_REQ_PACKAGES $PIP_OPT_PACKAGES
    return 0
}
