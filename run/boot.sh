#!/bin/zsh

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "$(which zsh)" ]; then
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL', zsh found '$(which zsh)', change shell to zsh and repeat: sudo chsh -s /usr/bin/zsh $USER" >&2
    else
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL' and zsh not detected" >&2
    fi
    return 1
fi


[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)


zmodload zsh/stat
zmodload zsh/datetime
zmodload zsh/parameter


JOSH_URL='https://github.com/YaakovTooth/Josh.git'
JOSH_PATH='custom/plugins/josh'
JOSH_SUBDIR_NAME='.josh'

perm_path=(
    $HOME/.cargo/bin
)

if [ -n "$VIRTUAL_ENV" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    perm_path=(
        $perm_path
        $VIRTUAL_ENV/bin
    )
fi

if [ -n "$PYTHON" ] && [ -d "$PYTHON/bin" ]; then
    perm_path=(
        $perm_path
        $PYTHON/bin
    )
else
    perm_path=(
        $perm_path
        $HOME/.python/default/bin
    )
fi

perm_path=(
    $perm_path
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

function fs_size {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[8]"
}

function fs_mtime {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[10]"
}

function fs_readlink {
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


function fs_basename {
    [ -z "$1" ] && return 1
    [[ "$1" -regex-match '[^/]+/?$' ]] && echo "$MATCH"
}

function fs_dirname {
    [ -z "$1" ] && return 1

    local result="$(fs_basename "$1")"
    [ -z "$result" ] && return 2

    let offset="${#1} - ${#result} -1"
    echo "${1[0,$offset]}"
}

function fs_realdir {
    [ -z "$1" ] && return 1

    local result="$(fs_realpath "$1")"
    [ -z "$result" ] && return 2

    local result="$(fs_dirname "$result")"
    [ -z "$result" ] && return 3

    echo "$result"
}

function fs_joshpath {
    if [ -z "$1" ] || [ -z "$JOSH" ]; then
        return 1
    fi

    local result="$(fs_realpath "$1")"
    if [ -z "$result" ]; then
        return 2
    fi

    let length="${#result} - ${#JOSH} - 2"
    echo "${result[${#result} - $length,${#result}]}"
}

function fs_resolver {
    if [ -n "$JOSH_REALPATH" ]; then
        return 0
    fi

    local result=''
    if [ -x "$commands[realpath]" ]; then
        local result="$commands[realpath] -q"

    elif [ -x "$commands[readlink]" ]; then
        if [ -z "$(uname | grep -i darwin)" ]; then
            local result="$commands[readlink] -f"
        else
            local result="$commands[readlink] -qf"
        fi
    fi

    if [ -n "$result" ]; then
        export JOSH_REALPATH="$result"
        return 0
    fi
    echo " - $0 fail: resolver isn't configured, need realpath or readlink" >&2
    return 1
}

function fs_realpath {
    local link="$1"
    if [ -z "$link" ]; then
        return 2

    elif [ -e "$link" ]; then
        if [ -L "$link" ]; then
            local node="$(fs_readlink "$1")"
            if [ -n "$node" ]; then

                if [[ "$node" =~ "^/" ]] && [ -x "$node" ] && [ ! -L "$node" ]; then
                    # target it's absolute path to executable, not to link
                    echo "$node"
                    return 0

                elif [[ "$link" =~ "^/" ]] && [[ ! "$node" =~ "/" ]]; then
                    # target it's relative path from source location
                    local node="$(fs_dirname "$link")/$node"
                    if [ -x "$node" ]; then
                        if [ ! -L "$node" ]; then
                            # target it's regular executable node
                            echo "$node"
                            return 0
                        else
                            # target it's symlink, okay
                            local node="$(fs_realpath "$node")"
                            echo "$node"
                            return "$?"
                        fi
                    fi
                fi
            fi
        fi

        fs_resolver
        if [ -z "$JOSH_REALPATH" ]; then
            echo "$link"
            return 3
        fi

        local cmd="$JOSH_REALPATH $link"
        eval "${cmd}"
    else
        echo " - $0 fail: '$link' doesn't exist" >&2
        return 1
    fi
}


function fs_retrieve_userhome {
    local login="${1:-\$USER}"

    # try to subshell expand
    local home="$($SHELL -c "echo ~$login" 2>/dev/null)"
    if [ "$?" -eq 0 ] && [ -x "$home" ]; then
        echo "$home"
        return 0
    fi

    if [ -x "$(builtin which getent)" ];  then
        # passwd with getent
        local home="$(getent passwd "$login" | cut -f6 -d: 2>/dev/null)"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi
    fi

    if [ -x "$(builtin which awk)" ];  then
        # passwd with awk
        local home="$(awk -v u="$login" -v FS=':' '$1==u {print $6}' /etc/passwd 2>/dev/null)"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi
    fi
    return 1
}


function fs_userhome {
    local home="$(fs_retrieve_userhome)"
    local real="$(fs_realpath $home)"

    if [ -x "$real" ]; then
        echo "$real"
    else
        printf " -- $0 warning: can't make real home path for HOME '$home', REAL '$(which realpath)', READLINK '$(which readlink)', fallback '$(fs_dirname "$home")/$(fs_basename "$home")'\n" >&2
        echo "$home"
    fi
}


function shortcut {
    [ -z "$ZSH" ] || [ -z "$1" ] && return 1

    local dir="$JOSH/bin"

    if [ -z "$2" ]; then
        local src="$dir/$(fs_basename "$1")"
        local dst="$1"

        if [ ! -x "$dst" ]; then
            printf " ** fail ($0): link source '$1' -> '$dst' isn't executable (exists?)\n" >&2
            return 2
        fi

    else
        if [[ "$1" =~ "/" ]]; then
            printf " ** fail ($0): link source '$1' couldn't contains slashes\n" >&2
            return 1
        fi
        local src="$dir/$1"
        local dst="$2"

        if [ ! -x "$dst" ]; then
            printf " ** fail ($0): link source '$2' -> '$dst' isn't executable (exists?)\n" >&2
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

function function_exists {
    declare -f "$1" >/dev/null
    if [ "$?" -gt 0 ]; then
        return 1
    fi
}


function which {
    local src="$*"

    if [ -z "$src" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 2

    elif [[ "$src" =~ "/" ]]; then
        if [ -e "$src" ]; then
            echo "$src"
            return 0
        fi
        printf " ** fail ($0): link name '$src' couldn't contains slashes\n" >&2
        return 3

    elif [ -z "$JOSH" ]; then
        printf " ++ warn ($0): root '$JOSH' isn't defined\n" >&2
    fi

    if [ -n "$JOSH" ] && [ -L "$JOSH/bin/$src" ]; then
        local dst="$JOSH/bin/$src"

    elif [ -n "$PYTHON_BINARIES" ] && [[ "$src" -regex-match '[0-9]+\.[0-9]+' ]] && [ -x "$PYTHON_BINARIES/$MATCH/bin/python" ]; then
        local dst="$PYTHON_BINARIES/$MATCH/bin/python"

    elif [ "$commands[$src]" ]; then
        local dst="$commands[$src]"

    elif function_exists 'lookup'; then
        local dst="$(lookup "$src")"
    fi

    if [ ! -n "$dst" ] || [ ! -x "$dst" ]; then
        local dst="$(eval "builtin which $src")"
        if [ ! -x "$dst" ]; then
            if [ -n "$dst" ] && [ ! $dst = "$src not found" ]; then
                printf " ++ warn ($0): '$src' isn't found, but $dst\n" >&2
                return 0
            fi
            return 1
        fi
    fi
    printf "$dst\n"
}


if [ -z "$JOSH" ]; then
    local redirect="$(fs_userhome)"
    if [ -x "$redirect" ] && [ ! "$redirect" = "$HOME" ]; then
        if [ ! "$(fs_realpath "$redirect")" = "$(fs_realpath "$HOME")" ]; then
            printf " ++ warn ($0): HOME:'$HOME' -> '$redirect'\n" >&2
        fi
        export HOME="$redirect"
    fi

    export ZSH="$HOME/$JOSH_SUBDIR_NAME"
    export JOSH="$ZSH/$JOSH_PATH"
    export PATH="$JOSH/bin:$PATH"
fi


if [[ -z ${(M)zsh_eval_context:#file} ]]; then
    if [ ! -x "$(builtin which git)" ]; then
        printf " ++ warn ($0): 'git' is required, but doesn't exist\n" >&2

    else
        JOSH_DEST="$HOME/$JOSH_SUBDIR_NAME.engine"  && [ -d "$JOSH_DEST" ] && rm -rf "$JOSH_DEST"
        JOSH_BASE="$HOME/$JOSH_SUBDIR_NAME.wrapper" && [ -d "$JOSH_BASE" ] && rm -rf "$JOSH_BASE"

        printf " -- info ($0): initial deploy to $JOSH_DEST, Josh to $JOSH_BASE\n" >&2
        git clone "$JOSH_URL" "$JOSH_BASE"
        [ "$?" -gt 0 ] && return 2

        if [ -n "$JOSH_BRANCH" ]; then
            builtin cd "$JOSH_BASE/run/"
            [ $? -gt 0 ] && return 3

            printf " -- info ($0): fetch Josh from '$JOSH_BRANCH'\n" >&2
            cmd="git fetch origin "$JOSH_BRANCH":"$JOSH_BRANCH" && git checkout --force --quiet $JOSH_BRANCH && git reset --hard $JOSH_BRANCH && git pull --ff-only --no-edit --no-commit --verbose origin $JOSH_BRANCH"

            printf " -- info ($0): -> $cmd\n" >&2
            $SHELL -c "$cmd"
            [ "$?" -gt 0 ] && return 4
        fi

        source $JOSH_BASE/run/strap.sh && \
        check_requirements && \
        prepare_and_deploy && \
        replace_existing_installation

        builtin cd "$HOME" && exec zsh
    fi


else
    source_file="$(fs_joshpath "$0")"
    if [ -n "$source_file" ] && [[ "${sourced[(Ie)$source_file]}" -eq 0 ]]; then
        sourced+=("$source_file")
        source "$(fs_dirname $0)/init.sh"
    fi
fi
