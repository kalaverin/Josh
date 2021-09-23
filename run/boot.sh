#!/bin/zsh

JOSH_SUBDIR=".josh"

function lookup() {
    if [ ! "$which" ]; then
        which="`which -p which 2>/dev/null`"
        if [ "$?" -eq 0 ] && [ -x "$which" ]; then
            # zsh internal which, we needs to
            which="builtin which -p"

        elif [ ! -x "$which" ]; then
            which="`which which 2>/dev/null`"
            if [ ! -x "$which" ]; then
                echo " - warning: \`which\` required" 1>&2
                which="which"
            fi
        fi
    fi

    if [ "$which" ]; then
        local cmd="$which $1"
        local result="`eval ${cmd}`"
        [ $? -eq 0 ] && [ -x "$result" ] && echo "$result"
    fi
}

function get_home() {
    if [ "`export | grep SUDO_ | wc -l`" -gt 0 ]; then
        # try to subshell expand
        local home="`$SHELL -c 'echo ~$USER'`"
        if [ -x "$home" ]; then
            echo "$home"
            return 0
        fi

        if [ -x "`lookup getent`" ];  then
            # passwd with getent
            local home="`getent passwd $USER | cut -f6 -d:`"
            if [ -x "$home" ]; then
                echo "$home"
                return 0
            fi
        fi

        if [ -x "`lookup awk`" ];  then
            # passwd with awk
            local home="`awk -v u="$USER" -v FS=':' '$1==u {print $6}' /etc/passwd`"
            if [ -x "$home" ]; then
                echo "$home"
                return 0
            fi
        fi
    else
        echo "$HOME"
        return 0
    fi
}

function get_realhome() {
    local home="`get_home`"
    if [ ! -x "$home" ]; then
        echo " - fatal: HOME=\`$home\` isn't acessible"
        return 1
    fi

    if [ -x "`lookup realpath`" ]; then
        echo "`realpath -q $home`"
    elif [ -x "`lookup readlink`" ]; then
        echo "`readlink -qf $home`"
    else
        echo "`dirname $home`/`basename $home`"
    fi
}

if [ -z "$JOSH" ]; then
    home="`get_realhome`"
    if [ -x "$home" ] && [ ! "$home" = "$HOME" ]; then
        if [ ! "`realpath $home`" = "`realpath $HOME`" ]; then
            echo " * set HOME:\`$HOME\` -> \`$home\`"
        fi
        export HOME="$home"
    fi

    export ZSH="$HOME/$JOSH_SUBDIR"
    export JOSH="$ZSH/custom/plugins/josh"
fi

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "`lookup zsh`" ]; then
        echo " - fatal: execute installer via zsh from `lookup zsh`"
    else
        echo " - fatal: \`zsh\` required"
    fi

else
    if [[ -z ${(M)zsh_eval_context:#file} ]]; then

        if [ ! -x "`lookup git`" ]; then
            echo " - fatal: \`git\` required"
        else
            cwd="`pwd`"

            JOSH_DEST="$HOME/.josh.omz"  && [ -d "$JOSH_DEST" ] && rm -rf "$JOSH_DEST"
            JOSH_BASE="$HOME/.josh.self" && [ -d "$JOSH_BASE" ] && rm -rf "$JOSH_BASE"

            echo " + initial deploy to $JOSH_DEST, Josh to $JOSH_BASE"
            git clone --depth 1 https://github.com/YaakovTooth/Josh.git $JOSH_BASE
            [ $? -gt 0 ] && return 2

            if [ "$JOSH_BRANCH" ]; then
                builtin cd "$JOSH_BASE/run/"
                [ $? -gt 0 ] && return 3

                echo " + fetch Josh from \`$JOSH_BRANCH\`"

                cmd="git fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && git checkout --force --quiet $JOSH_BRANCH && git reset --hard $JOSH_BRANCH && git pull --ff-only --no-edit --no-commit --verbose origin $JOSH_BRANCH"

                echo " -> $cmd" && $SHELL -c "$cmd"
                [ $? -gt 0 ] && return 4
            fi

            source $JOSH_BASE/run/strap.sh && \
            check_requirements && \
            prepare_and_deploy && \
            replace_existing_installation

            cd "$HOME" && exec zsh
        fi
    else
        if [ -z "$HTTP_GET" ]; then
            source "`dirname $0`/init.sh"
        fi
    fi
fi
