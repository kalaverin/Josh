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
    . "$JOSH/install/units/python.sh" && pip_deploy "$PIP_REQ_PACKAGES"
    . "$JOSH/install/units/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
}

function pull_update() {
    local cwd="`pwd`"
    cd "$JOSH"

    . "$JOSH/sources/functions/git.zsh"
    local local_branch="`git_current_branch`"
    if [ ! "$local_branch" ]; then
        cd "$cwd"
        return 1
    fi

    local branch="${1:-$local_branch}"
    [ ! "$branch" ] && local branch="master"
    [ "$branch" != "$local_branch" ] && $SHELL -c "git checkout $branch"

    git pull origin $branch
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
