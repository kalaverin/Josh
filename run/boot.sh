#!/bin/zsh

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "$(which zsh)" ]; then
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL', zsh found '$(which zsh)', change shell to zsh and repeat: sudo chsh -s /usr/bin/zsh $USER" >&2
    else
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL' and zsh not detected" >&2
    fi
    return 1
fi

[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)


zmodload zsh/stat
zmodload zsh/datetime
zmodload zsh/parameter

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
    $HOME/.brew/bin
)

function fs_size {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[8]"
}

function fs.mtime {
    if [ -z "$1" ]; then
        printf " ** fail ($0): call without args, I need to do — what?\n" >&2
        return 1
    fi

    builtin zstat -LA result "$1" 2>/dev/null
    [ "$?" -eq 0 ] && echo "$result[10]"
}

function fs.readlink {
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

function fs.basename {
    [ -z "$1" ] && return 1
    [[ "$1" -regex-match '[^/]+/?$' ]] && echo "$MATCH"
}

function fs.dirname {
    [ -z "$1" ] && return 1

    local result="$(fs.basename "$1")"
    [ -z "$result" ] && return 2

    let offset="${#1} - ${#result} -1"
    echo "${1[0,$offset]}"
}

function fs.realdir {
    [ -z "$1" ] && return 1

    local result="$(fs.realpath "$1")"
    [ -z "$result" ] && return 2

    local result="$(fs.dirname "$result")"
    [ -z "$result" ] && return 3

    echo "$result"
}

function fs.joshpath {
    if [ -z "$1" ] || [ -z "$ASH" ]; then
        return 1
    fi

    local result="$(fs.realpath "$1")"
    if [ -z "$result" ]; then
        return 2
    fi

    let length="${#result} - ${#ASH} - 2"
    echo "${result[${#result} - $length,${#result}]}"
}

function fs.gethash {
    if [ -z "$1" ] || [ -z "$ASH" ]; then
        return 1
    fi

    local meta result
    result="$(fs.realpath "$1")"
    if [ -z "$result" ]; then
        return 2
    fi

    builtin zstat -LA meta "$1" 2>/dev/null
    if [ "$?" -gt 0 ]; then
        return 3
    fi

    let length="${#result} - ${#ASH} - 2"
    echo "${result[${#result} - $length,${#result}]}:$meta[8]:$meta[10]"
}

function fs.resolver {
    if [ -n "$ASH_REALPATH" ]; then
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
        export ASH_REALPATH="$result"
        return 0
    fi
    printf " ** fail ($0): resolver isn't configured, need realpath or readlink\n" >&2
    return 1
}

function fs.realpath {
    local link="$1"
    if [ -z "$link" ]; then
        return 2

    elif [ -e "$link" ]; then
        if [ -L "$link" ]; then
            local node="$(fs.readlink "$1")"
            if [ -n "$node" ]; then

                if [[ "$node" =~ "^/" ]] && [ -x "$node" ] && [ ! -L "$node" ]; then
                    # target is absolute path to executable, not to link
                    echo "$node"
                    return 0

                elif [[ "$link" =~ "^/" ]] && [[ ! "$node" =~ "/" ]]; then
                    # target is relative path from source location
                    local node="$(fs.dirname "$link")/$node"
                    if [ -x "$node" ]; then
                        if [ ! -L "$node" ]; then
                            # target is regular executable node
                            echo "$node"
                            return 0
                        else
                            # target is symlink, okay
                            local node="$(fs.realpath "$node")"
                            echo "$node"
                            return "$?"
                        fi
                    fi
                fi
            fi
        fi

        fs.resolver
        if [ -z "$ASH_REALPATH" ]; then
            echo "$link"
            return 3
        fi

        local cmd="$ASH_REALPATH $link"
        eval "${cmd}"
    else
        printf " ** fail ($0): '$link' doesn't exist\n" >&2
        return 1
    fi
}

function fs.home.eval {
    local home
    local login="${1:-\$USER}"

    # try to subshell expand
    home="$($SHELL -c "echo ~$login" 2>/dev/null)"
    if [ "$?" -eq 0 ] && [ -x "$home" ]; then
        echo "$home"
        return 0
    fi

    if [ -x "$(builtin which getent)" ];  then
        # passwd with getent
        home="$(getent passwd "$login" | cut -f6 -d: 2>/dev/null)"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi
    fi

    if [ -x "$(builtin which awk)" ];  then
        # passwd with awk
        home="$(awk -v u="$login" -v FS=':' '$1==u {print $6}' /etc/passwd 2>/dev/null)"
        if [ "$?" -eq 0 ] && [ -x "$home" ]; then
            echo "$home"
            return 0
        fi
    fi
    return 1
}

function fs.home {
    local home="$(fs.home.eval)"
    local real="$(fs.realpath $home)"

    if [ -x "$real" ]; then
        echo "$real"
    else
        printf " -- $0 warning: can't make real home path for HOME '$home', REAL '$(which realpath)', READLINK '$(which readlink)', fallback '$(fs.dirname "$home")/$(fs.basename "$home")'\n" >&2
        echo "$home"
    fi
}

function fs.link {
    [ -z "$ASH" ] || [ -z "$1" ] && return 1

    local dir="$ASH/bin"

    if [ -z "$2" ]; then
        local src="$dir/$(fs.basename "$1")"
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

    if [ -L "$src" ] && [ ! "$dst" = "$(fs.realpath "$src")" ]; then
        unlink "$src"
    fi

    if [ ! -L "$src" ]; then
        [ ! -d "$dir" ] && mkdir -p "$dir"
        ln -s "$dst" "$src"
    fi
    echo "$dst"
    return 0
}

function fs.link.remove {
    [ -z "$ASH" ] || [ -z "$1" ] && return 1

    local dir="$ASH/bin"

    if [[ "$1" =~ "/" ]]; then
        fail $0 "'$1' couldn't contains slashes"
        return 1
    fi

    local src="$dir/$1"

    if [ ! -h "$src" ]; then
        fail $0 "'$src' isn't symbolic link"
        return 2
    else

        local dst="$(fs.readlink "$src")"
        unlink "$src"
        local ret="$?"

        if [ "$ret" -eq 0 ]; then
            warn $0 "unlink '$1' -> '$dst'"
        else
            fail $0 "unlink '$1' -> '$dst' failed: $ret"
            return "$ret"
        fi
    fi
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

    elif [ -z "$ASH" ]; then
        printf " ++ warn ($0): root '$ASH' isn't defined\n" >&2
    fi

    if [ -n "$ASH" ] && [ -L "$ASH/bin/$src" ]; then
        local dst="$ASH/bin/$src"

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


if [ -z "$ASH" ] || [ -z "$ZSH" ] || [ -z "$ASH_CACHE" ]; then
    local redirect="$(fs.home)"
    if [ -x "$redirect" ] && [ ! "$redirect" = "$HOME" ]; then
        if [ "$(fs.realpath "$redirect")" != "$(fs.realpath "$HOME")" ]; then
            printf " ++ warn ($0): HOME:'$HOME' -> '$redirect'\n" >&2
        fi
        export HOME="$redirect"
    fi

    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

    if [ ! -x "$ZSH" ]; then
        printf " ** fail ($0): oh-my-zsh dir \$ZSH:'$ZSH' isn't acessible, fallback to default\n" >&2
        export ZSH="$HOME/.oh-my-zsh"
        if [ ! -x "$ZSH" ]; then
            printf " == term ($0): oh-my-zsh dir \$ZSH:'$ZSH' isn't acessible, it's fatal\n" >&2
        fi
    fi

    export ASH="${ASH:-$HOME/.ash}"
    export PATH="$ASH/bin:$PATH"

    export ASH_CACHE="$HOME/.cache/ash"
    [ ! -d "$ASH_CACHE" ] && mkdir -p "$ASH_CACHE"
fi


if [[ -n ${(M)zsh_eval_context:#file} ]]; then
    local THIS_SOURCE="$(fs.gethash "$0")"
    if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
        SOURCES_CACHE+=("$THIS_SOURCE")
        source "$(fs.dirname $0)/init.sh"
    fi
else

    printf " ** fail ($0): do not run or eval, just source it\n" >&2
    return 2
fi
