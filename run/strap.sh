#!/bin/zsh

function check_requirements {
    source "$BASE/run/units/compat.sh" && check.compliance
    return "$?"
}

function prepare_and_deploy {
    if [ -z "$BASE" ]; then
        printf " ** fail ($0): BASE isn't set\n" >&2
        return 1
    fi
    local cwd="$PWD"
    builtin cd "$BASE"

    local branch="$(git rev-parse --quiet --abbrev-ref HEAD)"

    if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
        printf " ** fail ($0): can't upgrade from '$branch'\n" >&2
        return 2
    fi

    printf " -- info ($0): + pull '$branch' into '$BASE'\n" && \
    git pull --ff-only --no-edit --no-commit origin "$branch" && \
    if [ "$?" -gt 0 ]; then
        builtin cd "$cwd"
        return 3
    fi

    git update-index --refresh 1>/dev/null 2>/dev/null
    if [ "$?" -gt 0 ] || [ "$(git status --porcelain=v1 &>>/dev/null | wc -l)" -gt 0 ]; then
        printf " ** fail ($0): '$BASE' is dirty, stop\n" >&2
        builtin cd "$cwd"
        return 4

    elif [ -x "$(which git-restore-mtime)" ]; then
        git-restore-mtime --skip-missing --quiet
    fi

    printf " -- info ($0): works in '$PWD'\n" >&2 && \
    source "run/units/oh-my-zsh.sh" && \
    source "run/units/binaries.sh" && \
    source "run/units/configs.sh" && \
    source "lib/python.sh" && \
    source "lib/rust.sh"

    if [ "$?" -gt 0 ]; then
        builtin cd "$cwd"
        return 5
    fi

    pip.install $PIP_REQ_PACKAGES
    deploy_ohmyzsh && \
    deploy_extensions && \
    zero_configuration && \
    deploy_binaries && \
    cargo_deploy $CARGO_REQ_PACKAGES
    local retval="$?"

    zero_configuration
    builtin cd "$cwd"
    return "$retval"
}

function replace_existing_installation {
    if [ ! -z "$JOSH_DEST" ] && [ -d "$JOSH_DEST" ] && [ "$ZSH" != "$JOSH_DEST" ]; then
        source $JOSH_BASE/run/units/oh-my-zsh.sh && \
        merge_josh_ohmyzsh && \
        save_previous_installation && \
        rename_and_link

        [ "$?" -gt 0 ] && return 3

        builtin cd "$HOME"
        printf " ++ warn ($0): success! now just run: exec zsh\n" >&2
    fi
}

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -n "$JOSH_BASE" ]; then
        printf " -- info ($0): bootstrap from '$JOSH_BASE'\n" >&2
        BASE="$JOSH_BASE"

    elif [ -z "$JOSH" ]; then
        source "$(dirname $0)/boot.sh"
        BASE="$JOSH"

    fi
fi
