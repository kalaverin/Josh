#!/bin/zsh

zmodload zsh/stat
zmodload zsh/datetime
zmodload zsh/parameter

JOSH_PATH="custom/plugins/josh"
JOSH_SUBDIR_NAME=".josh"


function fs_readlink() {
    builtin zstat -LA result "$1" 2>/dev/null
    local retval="$?"
    local result="$result[14]"
    [ "$retval" -gt 0 ] && return "$retval"
    echo "$result"
}


function fs_realpath() {
    function get_resolver() {
        if [ -x "$commands[realpath]" ]; then
            echo "$commands[realpath] -q"

        elif [ -x "$commands[readlink]" ] && [ -z "$(uname | grep -i darwin)" ]; then
            echo "$commands[readlink] -qf"
        fi
    }

    local link="$1"
    if [ -z "$link" ]; then
        return 1

    elif [ -x "$link" ]; then
        if [[ "$link" =~ "^/" ]] && [ ! -L "$link" ]; then
            # it's not link, it is full file path
            echo "$link"
            return 0

        elif [ -L "$link" ]; then
            local node="`fs_readlink "$1"`"
            if [ -n "$node" ]; then

                if [[ "$node" =~ "^/" ]] && [ -x "$node" ] && [ ! -L "$node" ]; then
                    # target it's absolute path to executable, not to link
                    echo "$node"
                    return 0

                elif [[ "$link" =~ "^/" ]] && [[ ! "$node" =~ "/" ]]; then
                    # target it's relative path from source location
                    local node="`dirname $link`/$node"
                    if [ -x "$node" ]; then
                        if [ ! -L "$node" ]; then
                            # target it's regular executable node
                            echo "$node"
                            return 0
                        else
                            # target it's symlink, okay
                            local node="`fs_realpath "$node"`"
                            echo "$node"
                            return "$?"
                        fi
                    fi
                fi
            fi
        fi

        local resolver="`get_resolver`"
        if [ -z "$resolver" ]; then
            echo " - $0 fatal: resolver: \`$resolver\` isn't configured" >&2
            return link
        fi
        echo "`$SHELL -c "$resolver $link"`"

    else
        echo " - $0 fatal: link: \`$link\` isn't executive" >&2
        return 1
    fi
}


function path_last_modified() {
   local result="$(
        builtin zstat -L `echo "$PATH" | tr ':' ' ' ` 2>/dev/null | \
        grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
    )"
    echo "$result"
}


function reset_path() {
    local unified_path="$(
        echo "$PATH" | sd ':' '\n' \
        | runiq - | xargs -n 1 realpath 2>/dev/null \
        | sd '\n' ':' | sd '(^:|:$)' '' \
    )"
    [ "$?" = 0 ] && [ "$unified_path " ] && export PATH="$unified_path"
}


function rehash() {
    [ -z "$JOSH" ] && return 1

    reset_path
    builtin rehash
    which zsh
    typeset -Ag dirtimes

    builtin zstat -LnA result `find $JOSH/bin -type l | sed -z 's:\n: :g'`
    let record=0
    while true; do
        let name="$record * 15 + 1"
        let time="$record * 15 + 11"
        let link="$record * 15 + 15"
        let record="$record + 1"

        if [ -z "$result[$name]" ]; then
            break
        fi

        local key="`dirname "$result[$link]"`"
        local dtime="$dirtimes[$key]"
        if [ -z "$dtime" ]; then
            local dtime="`fstatm $key`"
            dirtimes[$key]="$dtime"
        fi

        local short="`basename $result[$name]`"
        let staled="$dtime > $result[$time]"
        if [ "$staled" -gt 0 ]; then
            unlink "$result[$name]"
            which "$short"
        fi

        if [ ! "$short" = "`basename "$result[$link]"`" ]; then
            # exclude manual remap, e.g. FreeBSD sed -> gsed, MacOS ls -> gls
            shortcut "$short" "`fs_realpath $commands[$short]`" 1>/dev/null
        fi
    done
    builtin rehash
}


function fstatm() {
    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[10]"
}


function shortcut() {
    [ -z "$ZSH" ] || [ -z "$1" ] && return 0
    [[ "$1" =~ "/" ]] && return 1

    local dir="$JOSH/bin"
    local src="$dir/$1"

    if [ -z "$2" ]; then
        if [ -L "$src" ]; then

            local dst="`fs_realpath "$src"`"
            if [ -x "$dst" ]; then
                echo "$dst"
            fi
        fi
        return 1

    else
        local dst="`fs_realpath $2`"
        if [ -z "$dst" ] || [ ! -x "$dst" ]; then
            return 2
        fi

        # if link already exists we need to check link destination
        if [ -L "$src" ] && [ ! "$dst" = "`fs_realpath "$src"`" ]; then
            unlink "$src"
        fi

        if [ ! -f "$src" ]; then
            [ ! -d "$dir" ] && mkdir -p "$dir"
            ln -s "$dst" "$src"
            echo "$dst"
        fi
        echo "$dst"
    fi
}


function which() {
    if [[ "$1" =~ "/" ]]; then
        if [ -x "$1" ] && [ ! -L "$1" ]; then
            echo "$1"
            return 0
        else
            echo "$(which `basename $1`)"
            return "$?"
        fi
    fi

    local node="`shortcut "$1"`"
    if [ -x "$node" ]; then
        echo "$node"
    else
        local node="`fs_realpath $commands[$1]`"
        echo "`shortcut "$1" "$node"`"
    fi
}

function get_home() {
    if [ "`export | grep SUDO_ | wc -l`" -gt 0 ]; then
        # try to subshell expand
        local home="`$SHELL -c 'echo ~$USER' 2>/dev/null`"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi

        if [ -x "`which getent`" ];  then
            # passwd with getent
            local home="`getent passwd $USER | cut -f6 -d: 2>/dev/null`"
            if [ "$?" -eq 0 ] && [ -x "$home" ]; then
                echo "$home"
                return 0
            fi
        fi

        if [ -x "`which awk`" ];  then
            # passwd with awk
            local home="`awk -v u="$USER" -v FS=':' '$1==u {print $6}' /etc/passwd 2>/dev/null`"
            if [ "$?" -eq 0 ] && [ -x "$home" ]; then
                echo "$home"
                return 0
            fi
        fi
    else
        echo "$HOME"
        return 0
    fi
}


function fs_userhome() {
    local home="`get_home`"
    local real="$(fs_realpath $home)"

    if [ -x "$real" ]; then
        if [ ! "$real" = "$home" ]; then
            echo " * link HOME:\`$home\` -> \`$real\`" >&2
        fi
        echo "$real"
    else
        echo " - $0 warning: can't make real home path for HOME:\`$home\` with REALPATH:\``which realpath`\`, READLINK:\``which readlink`\`, fallback:\``dirname $home`/`basename $home`\`" >&2
        echo "$home"
    fi
}


if [ -z "$JOSH" ]; then
    local home="`fs_userhome`"
    if [ -x "$home" ] && [ ! "$home" = "$HOME" ]; then
        if [ ! "`realpath $home`" = "`realpath $HOME`" ]; then
            echo " * set HOME:\`$HOME\` -> \`$home\`" >&2
        fi
        export HOME="$home"
    fi

    export ZSH="$HOME/$JOSH_SUBDIR_NAME"
    export JOSH="$ZSH/$JOSH_PATH"
fi



if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "`which zsh`" ]; then
        echo " - $0 fatal: current shell must be zsh, but SHELL:\`$SHELL\` and zsh binary:\``which zsh`\`" >&2
    else
        echo " - $0 fatal: current shell must be zsh, but SHELL:\`$SHELL\` and zsh not detected" >&2
    fi

else
    if [[ -z ${(M)zsh_eval_context:#file} ]]; then

        if [ ! -x "`which git`" ]; then
            echo " - fatal: \`git\` required"
        else
            cwd="`pwd`"

            JOSH_DEST="$HOME/$JOSH_SUBDIR_NAME.engine"  && [ -d "$JOSH_DEST" ] && rm -rf "$JOSH_DEST"
            JOSH_BASE="$HOME/$JOSH_SUBDIR_NAME.wrapper" && [ -d "$JOSH_BASE" ] && rm -rf "$JOSH_BASE"

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

    elif [ ! "$JOSH_INIT" -gt 0 ]; then
        source "`dirname $0`/init.sh"
        rehash
    fi
fi
