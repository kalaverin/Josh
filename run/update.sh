if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$JOSH" ]; then
        source "`dirname $0`/../run/boot.sh"
    fi
fi

function update_packages() {
    source "$JOSH/run/units/configs.sh" && zero_configuration
    source "$JOSH/run/units/binaries.sh" && deploy_binaries
    source "$JOSH/lib/rust.sh" && cargo_deploy $CARGO_REQ_PACKAGES
    source "$JOSH/lib/python.sh" && pip_deploy $PIP_REQ_PACKAGES
}

function pull_update() {
    local cwd="`pwd`" && builtin cd "$JOSH"

    local retval=1
    local local_branch="`git rev-parse --quiet --abbrev-ref HEAD`"

    if [ "$local_branch" ] && [ ! "$local_branch" = "HEAD" ]; then

        if [ -n "$JOSH_BRANCH" ]; then
            local target_branch="$JOSH_BRANCH"
        else
            local target_branch="${1:-$local_branch}"
        fi

        if [ ! "$target_branch" ]; then
            # if branch don't selected by hands - just use failover
            local target_branch="master"
        fi

        if [ "$target_branch" != "$local_branch" ]; then
            . "$JOSH/usr/units/git.zsh" && \
            git_checkout_branch "$target_branch" || return 1
        fi
        echo " + pull \`$target_branch\` to \`$JOSH\`"

        git pull --ff-only --no-edit --no-commit origin "$target_branch"
        local retval="$?"
    fi

    builtin cd "$cwd" && return "$retval"
}

function post_update() {
    update_packages
    source "$JOSH/run/units/compat.sh" && check_compliance
}

function deploy_extras() {
    local cwd="`pwd`"
    (source "$JOSH/lib/python.sh" && pip_extras || echo " - warning (python): something went wrong") && \
    (source "$JOSH/lib/rust.sh" && cargo_extras || echo " - warning (rust): something went wrong")
    builtin cd "$cwd"
}
