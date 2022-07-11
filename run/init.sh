if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "$(which zsh)" ]; then
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL', zsh found '$(which zsh)', change shell to zsh and repeat: sudo chsh -s /usr/bin/zsh $USER" >&2
    else
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL' and zsh not detected" >&2
    fi
    return 1
else

    SELF="$0"

    function ash.core {
        local root
        root="$(dirname "$SELF")" || return "$?"
        if [ -z "$root" ] || [ ! -x "$root" ]; then
            printf " ** fail ($0): something went wrong: root isn't detected\n" >&2
            return 1
        fi

        source "$root/core.sh"
        local retval="$?"
        if [ "$retval" -gt 0 ]; then
            printf " ** fail ($0): something went wrong: boot state=$retval\n" >&2
            return 1
        fi
        export ASH="$(fs.realpath "$root/../")"
    }

    function ash.obsolete {
        if [ -n "$HOME" ] && [ -d "$ZSH" ] && [[ ! "$ZSH" =~ '/.josh$' ]] && [ -d "$HOME/.josh" ]; then
            info $0 "you can remove old and unused installation, justrun : rm -rf $HOME/.josh/"
        fi
    }


    function ash.install {
        local branch cwd changes

        cwd="$PWD"
        function rollback() {
            builtin cd "$cwd"
            term "$1" "something went wrong, state=$2"
            return "$2"
        }

        ash.core || return "$?"
        [ ! -x "$ASH" ] && return 1
        source "$ASH/run/units/compat.sh" && compat.compliance || return "$(rollback "$0" "$?")"

        builtin cd "$ASH"

        changes="$(git status --porcelain=v1 &>>/dev/null | wc -l)" || return "$(rollback "$0" "$?")"
        if [ "$changes" -gt 0 ]; then
            warn "$0" "we have changes in $changes files, skip fetch & pull"

        else

            branch="$(git rev-parse --quiet --abbrev-ref HEAD)" || return "$(rollback "$0" "$?")"
            if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
                warn "$0" "can't update from '$branch'"
            else
                info "$0" "update '$branch' into '$ASH'"

                git pull --ff-only --no-edit --no-commit origin "$branch" || return "$(rollback "$0" "$?")"

                git update-index --refresh 1>/dev/null 2>/dev/null || return "$(rollback "$0" "$?")"
            fi
        fi

        if [ -x "$(which git-restore-mtime)" ]; then
            git-restore-mtime --skip-missing --quiet 2>/dev/null
        fi

        info "$0" "our home directory is '$PWD'"

        source "$ASH/run/units/oh-my-zsh.sh" && \
        source "$ASH/run/units/binaries.sh" && \
        source "$ASH/run/units/configs.sh" && \
        source "$ASH/lib/python.sh" && \
        source "$ASH/lib/rust.sh" || rollback "$0" "$?"

        # TODO: export ASH_VERBOSITY="1"

        pip.install $PIP_REQ_PACKAGES

        cfg.install && \
        omz.install && omz.plugins && \
        bin.install || return "$?"

        cargo.deploy $CARGO_REQ_PACKAGES

        cfg.install
        ASH_FORCE_CONFIGS=1 cfg.copy "$ASH/.zshrc" "$HOME/.zshrc"

        builtin cd "$cwd"
    }


    if [[ -n ${(M)zsh_eval_context:#file} ]]; then
        ash.core
        ash.obsolete
    else
        ash.install
    fi
fi
