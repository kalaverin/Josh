if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -z "$JOSH" ]; then
        source "`dirname $0`/../run/boot.sh"
    fi
fi

function pull_update() {
    local cwd="`pwd`" && builtin cd "$JOSH"

    local detected="`git rev-parse --quiet --abbrev-ref HEAD`"

    if [ "$detected" ] && [ ! "$detected" = "HEAD" ]; then

        if [ -n "$1" ]; then
            local branch="$1"
        elif [ -n "$JOSH_BRANCH" ]; then
            local branch="$JOSH_BRANCH"
        else
            local branch="$detected"
        fi

        if [ "$branch" != "$detected" ]; then
            source "$JOSH/usr/units/git.zsh" && git_fetch_checkout_branch "$branch"
            local retval=$?
        else
            local retval=0
        fi

        if [ $retval -eq 0 ]; then
            echo " + pull last changes from \`$branch\` to \``pwd`\`" && \
            git fetch --tags && git pull --ff-only --no-edit --no-commit origin "$branch"
            local retval="$?"

            if [ $retval -eq 0 ]; then
                git update-index --refresh &>>/dev/null
                if [ "$?" -gt 0 ] || [ "`git status --porcelain=v1 &>>/dev/null | wc -l`" -gt 0 ]; then
                    echo " - fatal: \``pwd`\` is dirty, couldn't automatic fast forward"
                    local retval=2
                elif [ -x "`which git-warp-time`" ]; then
                    git-warp-time --quiet
                fi
            else
                echo " - fatal: \``pwd`\` is dirty, pull failed"
            fi
        else
            echo " - fatal: \``pwd`\` checkout failed"
        fi
    else
        local retval=1
    fi
    builtin cd "$cwd" && return "$retval"
}

function post_update() {
    update_packages
    source "$JOSH/run/units/compat.sh" && check_compliance
}

function update_packages() {
    source "$JOSH/run/units/configs.sh" && \
    zero_configuration

    source "$JOSH/run/units/binaries.sh" && \
    deploy_binaries

    source "$JOSH/run/units/oh-my-zsh.sh" &&
    deploy_extensions

    source "$JOSH/lib/rust.sh" && \
    cargo_install "$CARGO_REQ_PACKAGES"
    cargo_update

    source "$JOSH/lib/python.sh" && \
    pip_install "$PIP_REQ_PACKAGES"
    pip_update
}

function deploy_extras() {
    local cwd="`pwd`"
    (source "$JOSH/lib/python.sh" && pip_extras || echo " - warning (python): something went wrong") && \
    (source "$JOSH/lib/rust.sh" && cargo_extras || echo " - warning (rust): something went wrong")
    builtin cd "$cwd"
}
