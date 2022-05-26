#!/bin/zsh

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "`which zsh`" ]; then
        echo " - $0 fatal: current shell must be zsh, but SHELL \`$SHELL\`, zsh found \``which zsh`\`, change shell to zsh and repeat: sudo chsh -s /usr/bin/zsh $USER" >&2
    else
        echo " - $0 fatal: current shell must be zsh, but SHELL \`$SHELL\` and zsh not detected" >&2
    fi
    return 1
fi


[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)


zmodload zsh/stat
zmodload zsh/datetime
zmodload zsh/parameter


JOSH_URL="https://github.com/YaakovTooth/Josh.git"
JOSH_PATH="custom/plugins/josh"
JOSH_SUBDIR_NAME=".josh"


perm_path=(
    $HOME/.cargo/bin
    $HOME/.python/default/bin
    $HOME/.brew/bin
    $HOME/.local/bin
    $HOME/bin
    /usr/local/bin
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/sbin
)


path=(
    $perm_path
    $path
)

function fs_size() {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[8]"
}

function fs_mtime() {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[10]"
}

function fs_readlink() {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    local retval="$?"
    local result="$result[14]"

    [ "$retval" -gt 0 ] && return "$retval"
    echo "$result"
}


function fs_basename() {
    [ -z "$1" ] && return 1
    [[ "$1" -regex-match '[^/]+/?$' ]] && echo "$MATCH"
}


function fs_dirname() {
    [ -z "$1" ] && return 1

    local result=`fs_basename $1`
    [ -z "$result" ] && return 2

    let offset="${#1} - ${#result} -1"
    echo "${1[0,$offset]}"
}


function fs_realdir() {
    [ -z "$1" ] && return 1

    local result="`fs_realpath "$1"`"
    [ -z "$result" ] && return 2

    local result="`fs_dirname "$result"`"
    [ -z "$result" ] && return 3

    echo "$result"
}


function fs_joshpath() {
    if [ -z "$1" ] || [ -z "$JOSH" ]; then
        return 1
    fi

    local result=`fs_realpath $1`
    if [ -z "$result" ]; then
        return 2
    fi

    let length="${#result} - ${#JOSH} - 2"
    echo "${result[${#result} - $length,${#result}]}"
}


function fs_realpath() {
    function get_resolver() {
        if [ -x "$commands[realpath]" ]; then
            echo "$commands[realpath] -q"

        elif [ -x "$commands[readlink]" ]; then
            if [ -z "$(uname | grep -i darwin)" ]; then
                echo "$commands[readlink] -n"
            else
                echo "$commands[readlink] -qf"
            fi
        fi
    }

    local link="$1"
    if [ -z "$link" ]; then
        return 1

    elif [ -e "$link" ]; then
        if [[ "$link" =~ "^/" ]] && [[ ! "$link" =~ "/../" ]] && [ ! -L "$link" ]; then
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
                    local node="`fs_dirname $link`/$node"
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
            echo "$link"
            return 3
        fi
        echo "`$SHELL -c "$resolver $link"`"

    else
        echo " - $0 fatal: \`$link\` invalid" >&2
        return 2
    fi
}


function fs_retrieve_userhome() {
    if [ "`export | grep SUDO_ | wc -l`" -gt 0 ]; then
        # try to subshell expand
        local home="`$SHELL -c 'echo ~$USER' 2>/dev/null`"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi

        if [ -x "`builtin which getent`" ];  then
            # passwd with getent
            local home="`getent passwd $USER | cut -f6 -d: 2>/dev/null`"
            if [ "$?" -eq 0 ] && [ -x "$home" ]; then
                echo "$home"
                return 0
            fi
        fi

        if [ -x "`builtin which awk`" ];  then
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
    local home="`fs_retrieve_userhome`"
    local real="$(fs_realpath $home)"

    if [ -x "$real" ]; then
        if [ ! "$real" = "$home" ]; then
            echo " * link HOME:\`$home\` -> \`$real\`" >&2
        fi
        echo "$real"
    else
        echo " - $0 warning: can't make real home path for HOME:\`$home\` with REALPATH:\``which realpath`\`, READLINK:\``which readlink`\`, fallback:\``fs_dirname $home`/`fs_basename $home`\`" >&2
        echo "$home"
    fi
}


function shortcut() {
    [ -z "$ZSH" ] || [ -z "$1" ] && return 1

    local dir="$JOSH/bin"

    if [ -z "$2" ]; then
        local src="$dir/`fs_basename $1`"
        local dst="`fs_realpath $1`"

        if [ ! -x "$dst" ]; then
            echo " - $0 fatal: link source \`$1\` -> \`$dst\` isn't executable (exists?)" >&2
            return 2
        fi

    else
        if [[ "$1" =~ "/" ]]; then
            echo " - $0 fatal: link source \`$1\` couldn't contains slashes" >&2
            return 1
        fi
        local src="$dir/$1"
        local dst="`fs_realpath $2`"

        if [ ! -x "$dst" ]; then
            echo " - $0 fatal: link source \`$2\` -> \`$dst\` isn't executable (exists?)" >&2
            return 2
        fi
    fi

    if [ -L "$src" ] && [ ! "$dst" = "`fs_realpath "$src"`" ]; then
        unlink "$src"
    fi

    if [ ! -L "$src" ]; then
        [ ! -d "$dir" ] && mkdir -p "$dir"
        ln -s "$dst" "$src"
    fi
    echo "$dst"
    return 0
}

function function_exists() {
    declare -f "$1" >/dev/null
    if [ "$?" -eq 0 ]; then
        echo "1"
    else
        return 1
    fi
}


function which() {
    local src="$*"

    if [ -z "$src" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 2

    elif [[ "$src" =~ "/" ]]; then
        printf " ** fail ($0): link name '$src' couldn't contains slashes\n" >&2
        return 2

    elif [ -z "$JOSH" ]; then
        printf " ++ warn ($0): kalash root '$JOSH' isn't defined\n" >&2
    fi

    if [ -n "$JOSH" ] && [ -L "$JOSH/bin/$src" ]; then
        local dst="$JOSH/bin/$src"

    elif [ "$commands[$src]" ]; then
        local dst="$commands[$src]"

    elif [ "`function_exists lookup`" -gt 0 ]; then
        local dst="$(lookup "$src")"
    fi

    if [ ! -n "$dst" ] || [ ! -x "$dst" ]; then
        local dst="$(eval "builtin which $src")"
        if [ ! -x "$dst" ]; then
            if [ -n "$dst" ] && [ ! $dst = "$src not found" ]; then
                printf " ++ fail ($0): '$src' isn't found, but $dst\n" >&2
                return 0
            fi
            return 1
        fi
    fi
    printf "$dst"
}


if [ -z "$JOSH" ]; then
    local home="`fs_userhome`"
    if [ -x "$home" ] && [ ! "$home" = "$HOME" ]; then
        if [ ! "`fs_realpath $home`" = "`fs_realpath $HOME`" ]; then
            echo " * set HOME:\`$HOME\` -> \`$home\`" >&2
        fi
        export HOME="$home"
    fi

    export ZSH="$HOME/$JOSH_SUBDIR_NAME"
    export JOSH="$ZSH/$JOSH_PATH"
    export PATH="$JOSH/bin:$PATH"
fi


if [[ -z ${(M)zsh_eval_context:#file} ]]; then
    if [ ! -x "`builtin which git`" ]; then
        echo " - fatal: \`git\` required"

    else
        cwd="`pwd`"

        JOSH_DEST="$HOME/$JOSH_SUBDIR_NAME.engine"  && [ -d "$JOSH_DEST" ] && rm -rf "$JOSH_DEST"
        JOSH_BASE="$HOME/$JOSH_SUBDIR_NAME.wrapper" && [ -d "$JOSH_BASE" ] && rm -rf "$JOSH_BASE"

        echo " + initial deploy to $JOSH_DEST, Josh to $JOSH_BASE" >&2
        git clone "$JOSH_URL" "$JOSH_BASE"
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
    source_file="`fs_joshpath "$0"`"
    if [ -n "$source_file" ] && [[ "${sourced[(Ie)$source_file]}" -eq 0 ]]; then
        sourced+=("$source_file")
        source "`fs_dirname $0`/init.sh"
    fi
fi
