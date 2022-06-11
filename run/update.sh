[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
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
        post.install
        return "$retval"
    }

    function post_update {
        update_internals
        post.install
    }

    function post_upgrade {
        update_internals
        update_packages
        post.install
    }

    function post.install {
        source "$JOSH/lib/python.sh" && pip.compliance.check
        source "$JOSH/run/units/compat.sh" && compat.compliance

        if [ -n "$ASH_POST_INSTALL_PYTHON" ]; then
            source "$JOSH/usr/units/python.zsh" && py.set "$ASH_POST_INSTALL_PYTHON"
            unset ASH_POST_INSTALL_PYTHON
        fi

        if [ -x "$commands[cfonts]" ]; then
            local msg='type exec zsh and have the fun'
            let enabled="$COLUMNS >= 177"
            if [ "$enabled" -eq "1" ]; then
                cfonts "$msg" -f slick -c yellow,blue
                return
            fi

            let enabled="$COLUMNS >= 142"
            if [ "$enabled" -eq "1" ]; then
                cfonts "$msg" -f shade -c yellow,blue
                return
            fi
        fi
        warn $0 "type 'exec zsh' for apply changes and have the fun!"
    }

    function update_internals {
        source "$JOSH/run/units/configs.sh" && \
        __setup.cfg.zero_configuration

        source "$JOSH/run/units/binaries.sh" && \
        __setup.bin.deploy_binaries

        source "$JOSH/run/units/oh-my-zsh.sh" &&
        __setup.omz.deploy_extensions

        source "$JOSH/lib/python.sh" && \
        pip.install "$PIP_REQ_PACKAGES"
        pip.update

        git.nested "$JOSH/usr/local"
    }

    function update_packages {
        source "$JOSH/lib/rust.sh" && \
        cargo.install "$CARGO_REQ_PACKAGES"
        cargo.update

        source "$JOSH/lib/brew.sh"
        brew.update
    }

    function deploy_extras {
        local cwd="$PWD"
        (source "$JOSH/lib/python.sh" && pip.extras || warn $0 "(python) something went wrong") && \
        (source "$JOSH/lib/rust.sh" && cargo.extras || warn $0 "(rust) something went wrong")
        (source "$JOSH/lib/brew.sh" && brew.env && (brew.extras || warn $0 "(brew) something went wrong"))
        builtin cd "$cwd"
    }
fi
