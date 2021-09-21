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
    local cwd="`pwd`" && builtin cd "$SOURCE_ROOT"

    . "run/units/configs.sh" && zero_configuration
    . "run/units/binaries.sh" && deploy_binaries

    . "lib/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
    . "lib/python.sh" && pip_deploy $PIP_REQ_PACKAGES

    builtin cd "$cwd"
}

function pull_update() {
    local cwd="`pwd`" && builtin cd "$SOURCE_ROOT"

    local retval=1
    local local_branch="`git rev-parse --quiet --abbrev-ref HEAD`"

    if [ "$local_branch" ] && [ ! "$local_branch" = "HEAD" ]; then
        local target_branch="${1:-$local_branch}"
        if [ ! "$target_branch" ]; then
            # if nothing selected, failover
            local target_branch="master"
        fi

        if [ "$target_branch" != "$local_branch" ]; then
            . "usr/units/git.zsh" && \
            git_checkout_branch "$target_branch" || return 1
        fi
        echo " + pull \`$target_branch\` to \`$SOURCE_ROOT\`"

        git pull --ff-only --no-edit --no-commit origin "$target_branch"
        local retval="$?"
    fi

    builtin cd "$cwd" && return "$retval"
}

function post_update() {
    local cwd="`pwd`" && builtin cd "$SOURCE_ROOT"

    update_packages
    . "run/units/compat.sh" && check_compliance
    builtin cd "$cwd"
}

function deploy_extras() {
    local cwd="`pwd`" && builtin cd "$SOURCE_ROOT"

    (. "lib/python.sh" && pip_extras || echo " - warning (python): something went wrong") && \
    (. "lib/rust.sh" && cargo_extras || echo " - warning (rust): something went wrong")
    builtin cd "$cwd"
}
