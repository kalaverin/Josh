if [ ! "$SOURCE_ROOT" ]; then
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../../")
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/install/init.sh
fi
if [ ! "$JOSH" ]; then
    echo " - fatal: init failed, REAL empty"
    return 255
fi

function update_packages() {
    . "$JOSH/install/units/python.sh" && pip_deploy $PIP_REQ_PACKAGES
    . "$JOSH/install/units/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
}

function pull_update() {
    cmd="git --work-tree=$JOSH --git-dir=$JOSH/.git"
    $SHELL -c "$cmd checkout ${1:-master} && $cmd pull"
    if [ $? -gt 0 ]; then
        echo ' - fatal: update failed :-\'
        return 1
    fi
    return 0
}

function post_update() {
    update_packages
    . "$JOSH/install/check.sh" && check_compliance
}

function deploy_extras() {
    . "$JOSH/install/units/python.sh" && pip_extras
    . "$JOSH/install/units/rust.sh" && cargo_extras
}
