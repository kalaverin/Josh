[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    source "$(dirname $0)/init.sh"

    if [[ -n ${(M)zsh_eval_context:#file} ]]; then
        if [ -z "$ASH" ]; then
            source "$(dirname $0)/core.sh"
        fi
    fi

    function pull.update {
        local cwd="$PWD"
        builtin cd "$ASH"

        local detected="$(git rev-parse --quiet --abbrev-ref HEAD)"

        if [ "$detected" ] && [ ! "$detected" = "HEAD" ]; then

            if [ -n "$1" ]; then
                local branch="$1"
            elif [ -n "$ASH_BRANCH" ]; then
                local branch="$ASH_BRANCH"
            else
                local branch="$detected"
            fi

            if [ "$branch" != "$detected" ]; then
                source "$ASH/usr/units/git.zsh" && git.branch.select "$branch"
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
        source "$ASH/core.sh"
        return "$retval"
    }

    function post.update {
        update.internals
        post.install
    }

    function post.upgrade {
        update.internals
        update.packages
        post.install
    }

    function post.install {
        source "$ASH/lib/python.sh" && pip.compliance.check
        source "$ASH/run/units/compat.sh" && compat.compliance

        if [ -n "$ASH_POST_INSTALL_PYTHON" ]; then
            source "$ASH/usr/units/python.zsh" && py.set "$ASH_POST_INSTALL_PYTHON"
            unset ASH_POST_INSTALL_PYTHON
        fi
        post.install.message
        omz update
    }

    function post.install.message {
        if [ -x "$commands[cfonts]" ]; then
            local msg='type exec zsh and enjoy!'
            let enabled="$COLUMNS >= 140"
            if [ "$enabled" -eq "1" ]; then
                cfonts "$msg" -f slick -c yellow,blue
                return
            fi

            let enabled="$COLUMNS >= 114"
            if [ "$enabled" -eq "1" ]; then
                cfonts "$msg" -f shade -c yellow,blue
                return
            fi
        fi
        warn $0 "type 'exec zsh' for apply changes and enjoy!"
    }

    function update.internals {
        source "$ASH/run/units/configs.sh" && \
        cfg.install

        source "$ASH/run/units/binaries.sh" && \
        bin.install

        source "$ASH/run/units/oh-my-zsh.sh" &&
        omz.plugins

        source "$ASH/usr/units/git.zsh" && \
        git.nested "$ASH/usr/local"
    }

    function update.packages {
        source "$ASH/lib/python.sh" && \
        pip.install "$PIP_REQ_PACKAGES"
        pip.update

        source "$ASH/lib/rust.sh" && \
        cargo.install "$CARGO_REQ_PACKAGES"
        cargo.update

        source "$ASH/lib/brew.sh"
        brew.update
    }

    function deploy.extras {
        local cwd="$PWD"
        (source "$ASH/lib/python.sh" && pip.extras || warn $0 "(python) something went wrong") && \
        (source "$ASH/lib/rust.sh" && cargo.extras || warn $0 "(rust) something went wrong")
        (source "$ASH/lib/brew.sh" && brew.env && (brew.extras || warn $0 "(brew) something went wrong"))
        builtin cd "$cwd"
    }


    typeset -Agx DEPRECATIONS=()
    DEPRECATIONS[pull_update]=pull.update
    DEPRECATIONS[post_update]=post.update
    DEPRECATIONS[post_upgrade]=post.upgrade
    DEPRECATIONS[update_internals]=update.internals
    DEPRECATIONS[update_packages]=update.packages
    DEPRECATIONS[deploy_extras]=deploy.extras

    for deprecated func in ${(kv)DEPRECATIONS}; do
        eval {"$deprecated() { warn \$0 \"deprecated and must be removed, use '$func' instead\"; $func \$* }"}
    done
fi
