#!/bin/zsh

JOSH_SUBDIR=".josh"

typeset -A LOOKUP_CACHE

function lookup_in_hier() {
    local order=(/usr/local/bin /usr/local/sbin /usr/bin /usr/sbin /bin /sbin)
    for sub in $order; do
        if [ -x "$sub/$1" ]; then
            echo "$sub/$1"
            break
        fi
    done
}

function lookup() {
    if [ -x "$LOOKUP_CACHE[$1]" ]; then
        echo "$LOOKUP_CACHE[$1]"

    else
        local result="`builtin which -p "$1" 2>/dev/null`"
        if [ "$?" -eq 0 ] && [ -x "$result" ]; then
            LOOKUP_CACHE[$1]="$result"
            echo "$result"
        else
            local result="`builtin which -p sh 2>/dev/null`"
            if [ "$?" -gt 0 ] || [ ! -x "$result" ]; then
                # builtin which fails - extraordinary
                echo " - $0 fatal: failed: \"builtin which -p sh\"" >&2
                return 2
            else
                # fallback - just scan hardcoded PATH
                local result="`lookup_in_hier "$1" 2>/dev/null`"
                if [ "$?" -eq 0 ] && [ -x "$result" ]; then
                    LOOKUP_CACHE[$1]="$result"
                    echo "$result"
                else
                    return 1
                fi
            fi
        fi
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
        echo " - $0 fatal: HOME:\`$home\` isn't acessible" >&2
        return 1
    fi

    if [ -x "`lookup realpath`" ]; then
        echo "`realpath -q $home`"

    elif [ -x "`lookup readlink`" ] && [ -z "$(uname | grep -i darwin)" ]; then
        echo "`readlink -qf $home`"

    else
        local sudbir="`dirname $home`"
        if [ "$?" -eq 0 ] && [ -n "$subdir" ]; then
            local homedir="`basename $home`"
            if [ "$?" -eq 0 ] && [ -n "$homedir" ]; then
                echo "$sudbir/$homedir"
                return 0
            fi
        fi
        echo " - $0 warning: can't make real home path for HOME:\`$home\` with REALPATH:\``lookup realpath`\`, READLINK:\``lookup readlink`\`, fallback:\``dirname $home`/`basename $home`\`" >&2
        echo "$home"
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
        echo " - $0 fatal: current shell must be zsh, but SHELL:\`$SHELL\` and zsh binary:\``lookup zsh`\`" >&2
    else
        echo " - $0 fatal: current shell must be zsh, but SHELL:\`$SHELL\` and zsh not detected" >&2
    fi

else
    if [[ -z ${(M)zsh_eval_context:#file} ]]; then

        if [ ! -x "`lookup git`" ]; then
            echo " - fatal: \`git\` required"
        else
            cwd="`pwd`"

            JOSH_DEST="$HOME/$JOSH_SUBDIR.engine"  && [ -d "$JOSH_DEST" ] && rm -rf "$JOSH_DEST"
            JOSH_BASE="$HOME/$JOSH_SUBDIR.wrapper" && [ -d "$JOSH_BASE" ] && rm -rf "$JOSH_BASE"

            echo " + initial deploy to $JOSH_DEST, Josh to $JOSH_BASE" >&2
            git clone https://github.com/YaakovTooth/Josh.git $JOSH_BASE
            [ $? -gt 0 ] && return 2

            if [ "$JOSH_BRANCH" ]; then
                builtin cd "$JOSH_BASE/run/"
                [ $? -gt 0 ] && return 3

                echo " + fetch Josh from \`$JOSH_BRANCH\`" >&2

                cmd="git fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && git checkout --force --quiet $JOSH_BRANCH && git reset --hard $JOSH_BRANCH && git pull --ff-only --no-edit --no-commit --verbose origin $JOSH_BRANCH"

                echo " -> $cmd" >&2 && $SHELL -c "$cmd"
                [ $? -gt 0 ] && return 4
            fi

            source $JOSH_BASE/run/strap.sh && \
            check_requirements && \
            prepare_and_deploy && \
            replace_existing_installation

            builtin cd "$HOME" && exec zsh
        fi
    else
        if [ -z "$HTTP_GET" ]; then
            source "`dirname $0`/init.sh"
        fi
    fi
fi
