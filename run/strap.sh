#!/bin/zsh

function check_requirements() {
    source $BASE/run/units/compat.sh && check_compliance && return $?
}

function prepare_and_deploy() {
    if [ -z "$BASE" ]; then
        echo " - fatal: BASE isn't exists"
        return 127
    fi
    cwd="`pwd`" && builtin cd "$BASE"

    local branch="`git rev-parse --quiet --abbrev-ref HEAD`"

    if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
        echo " - fatal: can't upgrade from \`$branch\`"
        return 1
    fi

    echo " + pull last changes from \`$branch\` to \`$BASE\`" && \
    git pull --ff-only --no-edit --no-commit origin "$branch" && \
    [ $? -gt 0 ] && return 2

    git update-index --refresh &>>/dev/null
    if [ "$?" -gt 0 ] || [ "`git status --porcelain=v1 &>>/dev/null | wc -l`" -gt 0 ]; then
        echo " - fatal: \`$BASE\` is dirty, couldn't automatic fast forward"
        return 3

    elif [ -x "`which git-restore-mtime`" ]; then
        git-restore-mtime --skip-missing --quiet
    fi

    echo " + works in \``pwd`\`" && \
    source run/units/oh-my-zsh.sh && \
    source run/units/binaries.sh && \
    source run/units/configs.sh && \
    source lib/python.sh && \
    source lib/rust.sh

    [ $? -gt 0 ] && return 4

    pip_install $PIP_REQ_PACKAGES
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

function replace_existing_installation() {
    if [ ! -z "$JOSH_DEST" ] && [ -d "$JOSH_DEST" ] && [ "$ZSH" != "$JOSH_DEST" ]; then
        source $JOSH_BASE/run/units/oh-my-zsh.sh && \
        merge_josh_ohmyzsh && \
        save_previous_installation && \
        rename_and_link

        [ $? -gt 0 ] && return 3

        builtin cd $HOME && echo ' + oh my josh! now, just run: exec zsh' 1>&2
    fi
}

if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    if [ -n "$JOSH_BASE" ]; then
        echo " + bootstrap from \`$JOSH_BASE\`"
        BASE="$JOSH_BASE"

    elif [ -z "$JOSH" ]; then
        source "`dirname $0`/boot.sh"
        BASE="$JOSH"

    fi
fi
