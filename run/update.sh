if [ "$JOSH" ] && [ -d "$JOSH" ]; then
    export SOURCE_ROOT="`realpath $JOSH`"

elif [ ! "$SOURCE_ROOT" ]; then
    if [ ! -f "`which -p realpath`" ]; then
        export SOURCE_ROOT="`dirname $0`/../"
    else
        export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
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

function update_packages() {
    . "$SOURCE_ROOT/lib/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
    . "$SOURCE_ROOT/lib/python.sh" && pip_deploy $PIP_REQ_PACKAGES

    . "$SOURCE_ROOT/run/units/binaries.sh" && deploy_binaries
    . "$SOURCE_ROOT/run/units/configs.sh" && zero_configuration
}

function pull_update() {
    local cwd="`pwd`"

    cd "$SOURCE_ROOT"
    . "$SOURCE_ROOT/usr/units/git.zsh"

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
    . "$SOURCE_ROOT/run/units/compat.sh" && check_compliance
    cd "$cwd"
}

function deploy_extras() {
    local cwd="`pwd`"
    (. "$SOURCE_ROOT/lib/python.sh" && pip_extras || \
        echo " - warning: something wrong") && \
    . "$SOURCE_ROOT/lib/rust.sh" && cargo_extras
    cd "$cwd"
}
