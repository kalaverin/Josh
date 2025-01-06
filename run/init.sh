#!/bin/zsh

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "$(which zsh)" ]; then
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL', zsh found '$(which zsh)', change shell to zsh and repeat: chsh -s '$(which zsh)' $USER\n" >&2
    else
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL' and zsh not detected\n" >&2
    fi
    return 1

else
    SELF="$0"

    function dir.check {
        if [ -z "$1" ]; then
            printf " ** fail ($0): '$1' failed: empty\n" >&2
            return 1

        elif [ ! -d "$1" ]; then
            printf " ** fail ($0): '$1' failed: isn't directory\n" >&2
            return 2

        elif [ ! -x "$1" ]; then
            printf " ** fail ($0): '$1' failed: isn't acessible directory\n" >&2
            return 3
        fi
    }

    function ash.core {
        local fname retval root
        root="$(dirname "$SELF")"
        retval="$?"

        if dir.check "$root" && [ "$retval" -eq 0 ]; then

            fname="$root/core.sh"
            if [ ! -d "$root" ]; then
                printf " ** fail ($0): source '$fname' failed: isn't exists\n" >&2
                return 1
            fi

            source "$fname"
            retval="$?"
            if [ "$retval" -gt 0 ]; then
                printf " ** fail ($0): source '$fname' failed: catch $retval\n" >&2
                return "$retval"
            fi

            root="$(fs.realpath "$root/../")"
            retval="$?"

            if dir.check "$root" && [ "$retval" -eq 0 ]; then
                export ASH="$root"
                return 0
            fi

            printf " ** fail ($0): source '$fname' failed: catch $retval\n" >&2
            return "$retval"

        elif [ "$retval" -gt 0 ]; then
            printf " ** fail ($0): '$SELF' failed: '$root' detected, catch $retval\n" >&2

        fi

        return 1
    }


    function ash.obsolete {
        if [ -d "$HOME/.josh" ] && [ -n "$HOME" ] && [ -d "$ZSH" ] && [[ ! "$ZSH" =~ '/.josh$' ]] && [[ ! "$ASH" =~ '/.josh/custom/plugins/josh$' ]]; then
            info $0 "you can remove old and unused installation, just run: rm -rf $HOME/.josh/"
        fi
    }


    function ash.install {
        local branch cwd changes

        cwd="$PWD"
        function rollback() {
            builtin cd "$cwd"
            term "$2:$1" "something went wrong, state=$3"
            printf "$3" && return "$3"
        }

        ash.core || return "$?"
        [ ! -x "$ASH" ] && return 1
        source "$ASH/run/units/compat.sh" && compat.compliance \
            || return "$(rollback "compat" "$0" "$?")"

        builtin cd "$ASH"

        changes="$(git status --porcelain=v1 &>>/dev/null | wc -l)" \
            || return "$(rollback "tree.modified" "$0" "$?")"

        if [ "$changes" -gt 0 ]; then
            warn "$0" "we have changes in $changes files, skip fetch & pull"

        else

            branch="$(git rev-parse --quiet --abbrev-ref HEAD)" \
                || return "$(rollback "tree.branch" "$0" "$?")"

            if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
                warn "$0" "can't update from '$branch'"
            else
                info "$0" "update '$branch' into '$ASH'"

                git pull --ff-only --no-edit --no-commit origin "$branch" \
                    || return "$(rollback "tree.pull" "$0" "$?")"

                git update-index --refresh 1>/dev/null 2>/dev/null \
                    || return "$(rollback "tree.index" "$0" "$?")"
            fi
        fi

        if [ -x "$(which git-restore-mtime)" ]; then
            git-restore-mtime --skip-missing --quiet 2>/dev/null
        fi

        info "$0" "our home directory is '$PWD'"

        source "$ASH/run/units/oh-my-zsh.sh" && \
        source "$ASH/run/units/binaries.sh"  && \
        source "$ASH/run/units/configs.sh"   && \
        source "$ASH/run/update.sh"          && \
        source "$ASH/lib/python.sh"          && \
        source "$ASH/lib/go.sh"              && \
        source "$ASH/lib/ruby.sh"            && \
        source "$ASH/lib/rust.sh"        || return "$(rollback "core" "$0" "$?")"
        pip.install $PIP_REQ_PACKAGES    || return "$(rollback "pip" "$0" "$?")"
        cfg.install
        omz.install && omz.plugins       || return "$(rollback "oh-my-zsh" "$0" "$?")"
        bin.install                      || return "$(rollback "custom" "$0" "$?")"
        cargo.deploy $CARGO_REQ_PACKAGES || return "$(rollback "cargo" "$0" "$?")"
        go.deploy $GO_REQ_PACKAGES       || return "$(rollback "go" "$0" "$?")"

        info "$0" "success! finally: replace ~/.zshrc with ash loader"

        cfg.install
        ASH_FORCE_CONFIGS=1 cfg.copy "$ASH/.zshrc" "$HOME/.zshrc"
        post.install.message

        builtin cd "$cwd"
    }


    if [[ -n ${(M)zsh_eval_context:#file} ]]; then
        ash.core
        ash.obsolete
    else
        ash.install
    fi
fi
