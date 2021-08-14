if [ ! "$SOURCE_ROOT" ]; then
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
    echo " + init from $SOURCE_ROOT"
    . $SOURCE_ROOT/run/init.sh
fi
if [ ! "$JOSH" ]; then
    echo " - fatal: init failed, REAL empty"
    return 255
fi

function update_packages() {
    . "$JOSH/lib/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
    . "$JOSH/lib/python.sh" && pip_deploy $PIP_REQ_PACKAGES

    . "$JOSH/run/units/binaries.sh" && deploy_binaries
    . "$JOSH/run/units/configs.sh" && zero_configuration
}

function pull_update() {
    local cwd="`pwd`"

    cd "$JOSH"
    . "$JOSH/usr/units/git.zsh"

    local retval=1
    local local_branch="`git_current_branch`"

    if [ "$local_branch" ]; then
        local branch="${1:-$local_branch}"
        [ ! "$branch" ] && local branch="master"
        [ "$branch" != "$local_branch" ] && git checkout $branch

        git pull origin $branch
        local retval="$?"
    fi

    cd "$cwd"
    return "$retval"
}

function post_update() {
    local cwd="`pwd`"
    update_packages
    . "$JOSH/run/units/compat.sh" && check_compliance
    cd "$cwd"
}

function deploy_extras() {
    local cwd="`pwd`"
    (. "$JOSH/lib/python.sh" && pip_extras || \
        echo " - warning: something wrong") && \
    . "$JOSH/lib/rust.sh" && cargo_extras
    cd "$cwd"
}
