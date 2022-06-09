[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs_gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    source "$(dirname $0)/init.sh"

    if [[ -n ${(M)zsh_eval_context:#file} ]]; then
        if [ -z "$JOSH" ]; then
            source "$(dirname $0)/../run/boot.sh"
        fi
    fi

    function pull_update {
        local cwd="$PWD"
        builtin cd "$JOSH"

        local detected="$(git rev-parse --quiet --abbrev-ref HEAD)"

        if [ "$detected" ] && [ ! "$detected" = "HEAD" ]; then

            if [ -n "$1" ]; then
                local branch="$1"
            elif [ -n "$JOSH_BRANCH" ]; then
                local branch="$JOSH_BRANCH"
            else
                local branch="$detected"
            fi

            if [ "$branch" != "$detected" ]; then
                source "$JOSH/usr/units/git.zsh" && git.branch.select "$branch"
                local retval=$?
            else
                local retval="0"
            fi

            if [ "$retval" -eq 0 ]; then
                info $0 "pull '$branch' into $PWD"
                git fetch --tags && git pull --ff-only --no-edit --no-commit origin "$branch"
                local retval="$?"

                if [ "$retval" -eq 0 ]; then
                    git update-index --refresh 1>/dev/null 2>/dev/null
                    if [ "$?" -gt 0 ] || [ "$(git status --porcelain=v1 &>>/dev/null | wc -l)" -gt 0 ]; then
                        fail $0 "'$CWD' is dirty, stop\n"
                        local retval="2"
                    fi
                else
                    fail $0 "'$CWD' is dirty, stop\n"
                fi
            else
                fail $0 "'$CWD' is dirty, stop\n"
            fi
        else
            local retval="1"
        fi

        if [ -x "$(which git-restore-mtime)" ]; then
            git-restore-mtime --skip-missing --quiet
        fi
        builtin cd "$cwd"
        return "$retval"
    }

    function post_update {
        update_internals
        source "$JOSH/run/units/compat.sh" && compat.compliance
    }

    function post_upgrade {
        update_internals
        update_packages
        source "$JOSH/run/units/compat.sh" && compat.compliance
    }

    function update_internals {
        source "$JOSH/run/units/configs.sh" && \
        zero_configuration

        source "$JOSH/run/units/binaries.sh" && \
        deploy_binaries

        source "$JOSH/run/units/oh-my-zsh.sh" &&
        deploy_extensions

        source "$JOSH/lib/python.sh" && \
        pip.install "$PIP_REQ_PACKAGES"
        pip.update

        git.nested "$JOSH/usr/local"
    }

    function update_packages {
        source "$JOSH/lib/rust.sh" && \
        cargo_install "$CARGO_REQ_PACKAGES"
        cargo_update

        source "$JOSH/lib/brew.sh"
        brew_update
    }

    function deploy_extras {
        local cwd="$PWD"
        (source "$JOSH/lib/python.sh" && pip.extras || warn $0 "(python) something went wrong") && \
        (source "$JOSH/lib/rust.sh" && cargo_extras || warn $0 "(rust) something went wrong")
        (source "$JOSH/lib/brew.sh" && brew_env && (brew_extras || warn $0 "(brew) something went wrong"))
        builtin cd "$cwd"
    }
fi
