#!/bin/sh

MIN_PYTHON_VERSION=3.6

PIP_REQ_PACKAGES=(
    \"pip\<=20.3.4\"
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

function python_init() {
    . $JOSH/install/check.sh

    if [ -f "$PYTHON3" ]; then
        version_not_compatible \
            $MIN_PYTHON_VERSION \
            `$PYTHON3 --version 2>&1 | tabulate -i 2` || return 0
    fi

    for dir in $(sh -c "echo "$PATH" | sed 's#:#\n#g' | sort -su"); do
        for exe in $(find $dir -type f -name 'python*' 2>/dev/null | sort -Vr); do
            local version=$($exe --version 2>&1 | grep -Po '([\d\.]+)$')
            version_not_compatible $MIN_PYTHON_VERSION $version || local result="$exe"
            [ "$result" ] && break
        done
        [ "$result" ] && break
    done
    [ "$result" ] && export PYTHON3="`realpath $result`"
}

function pip_init() {
    python_init
    if [ ! -f "$PYTHON3" ]; then
        echo " - fatal: python>=3.6 required!"
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
    local cwd="`pwd`"
    local venv="$VIRTUAL_ENV"

    if [ "$venv" != "" ]; then
        cd $venv/bin && source activate && deactivate; cd $cwd
    fi

    pip_init || return $?
    if [ ! -f "$PIP_EXE" ]; then
        echo " - fatal: cargo exe $PIP_EXE isn't found!"
        return 1
    fi

    for line in $@; do
        $SHELL -c "PIP_REQUIRE_VIRTUALENV=false $PIP_EXE install --upgrade --upgrade-strategy=eager $line"
    done

    if [ "$venv" != "" ]; then
        cd $venv/bin && source activate
    fi
    return 0
}


function pip_extras() {
    pip_deploy "$PIP_REQ_PACKAGES $PIP_OPT_PACKAGES"
    return 0
}
