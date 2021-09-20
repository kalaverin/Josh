#!/bin/sh

if [ ! -f "`which -p realpath`" ]; then
    export SOURCE_ROOT="`dirname $0`/../"
else
    export SOURCE_ROOT=$(sh -c "realpath `dirname $0`/../")
fi

if [ ! "$REAL" ]; then
    echo " + init from $SOURCE_ROOT" 1>&2
    . $SOURCE_ROOT/run/init.sh

    if [ ! "$REAL" ]; then
        echo " - fatal: init failed" 1>&2
        return 255
    fi
fi

if [ ! "$HTTP_GET" ]; then
    echo " - fatal: curl, wget, fetch or httpie doesn't exists" 1>&2
    exit 255
else
    echo " * http backend: $HTTP_GET" 1>&2
fi

export CONFIG_DIR="$REAL/.config"
export MERGE_DIR="$REAL/josh.base"


function check_requirements() {
    . $SOURCE_ROOT/run/units/compat.sh
    check_compliance && return 255
    return 0
}

function prepare_and_deploy() {
    local branch="`git rev-parse --quiet --abbrev-ref HEAD`"

    if [ "$branch" = "HEAD" ]; then
        echo " - fatal: can't upgrade from \`$branch\`"
        return 1
    fi

    echo " + pull \`$branch\`" && \
    cd "$SOURCE_ROOT" && \
    git pull --ff-only --no-edit --no-commit origin "$branch" && \
    [ $? -gt 0 ] && return 2

    echo " + works in \``pwd`\`" && \
    . run/units/oh-my-zsh.sh && \
    . run/units/binaries.sh && \
    . run/units/configs.sh && \
    . lib/python.sh && \
    . lib/rust.sh

    if [ ! "$SOURCE_ROOT" = "`pwd`" ]; then
        echo " - fatal: WORKDIR=\``pwd`\` != SOURCE_ROOT=\`$SOURCE_ROOT\`"
        return 3
    fi

    [ $? -gt 0 ] && return 4

    pip_deploy $PIP_REQ_PACKAGES && \
    deploy_ohmyzsh && \
    deploy_extensions && \
    deploy_binaries && \
    zero_configuration && \
    cargo_deploy $CARGO_REQ_PACKAGES

    [ $? -gt 0 ] && return 5

    return 0
}

function replace_existing_installation() {
    if [ "$ZSH" != "$SOURCE_ROOT" ]; then
        merge_josh_ohmyzsh && \
        save_previous_installation && \
        rename_and_link

        [ $? -gt 0 ] && return 3

        cd $REAL && echo ' + oh my josh!' 1>&2
    fi
}
