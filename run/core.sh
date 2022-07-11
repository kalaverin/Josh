#!/bin/zsh

if [[ ! "$SHELL" =~ "/zsh$" ]]; then
    if [ -x "$(which zsh)" ]; then
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL', zsh found '$(which zsh)', change shell to zsh and repeat: sudo chsh -s /usr/bin/zsh $USER" >&2
    else
        printf " ** fail ($0): current shell must be zsh, but SHELL '$SHELL' and zsh not detected" >&2
    fi
    return 1
else

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


    function __log.spaces {
        if [ -z "$1" ] || [ ! "$1" -gt 0 ]; then
            return

        elif [ "$1" -gt 0 ]; then
            for i in {1..$1}; do
                printf "\n"
            done
        fi
    }

    if [ "$commands[pastel]" ]; then
        alias draw="pastel -m 8bit paint -n"
        function __log.draw {
            __log.spaces "$PRE"
            local msg="$(echo "${@:6}" | sd '[\$"]' '\\$0')"
            printf "$(eval "draw $2 ' $1 $4 ($5):'")$(eval "draw $3 \" $msg\"")"
            __log.spaces "${POST:-1}"
        }
        function depr { __log.draw '~~' 'indigo' 'deeppink' $0 $* >&2 }
        function info { __log.draw '--' 'limegreen' 'gray' $0 $* >&2 }
        function warn { __log.draw '++' 'yellow' 'gray' $0 $* >&2 }
        function fail { __log.draw '==' 'red --bold' 'white --bold' $0 $* >&2 }
        function term { __log.draw '**' 'white --on red --bold' 'white --bold' $0 $* >&2 }

    else
        function __log.draw {
            __log.spaces "$PRE"

            if [ -x "$commands[sd]" ]; then
                local msg="$(echo "${@:6}" | sd '[\$"]' '\\$0')"
            else
                local msg="${@:6}"
            fi

            printf "$2 $1 $4 ($5):$3 $msg\033[0m" >&2
            __log.spaces "${POST:-1}"
        }
        function depr { __log.draw '~~' '\033[0;35m' '\033[0;34m' $0 $* >&2 }
        function info { __log.draw '--' '\033[0;32m' '\033[0m' $0 $* >&2 }
        function warn { __log.draw '++' '\033[0;33m' '\033[0m' $0 $* >&2 }
        function fail { __log.draw '==' '\033[1;31m' '\033[0m' $0 $* >&2 }
        function term { __log.draw '**' '\033[42m\033[0;101m' '\033[0m' $0 $* >&2 }
    fi


    if [ -x "$commands[fetch]" ]; then
        export HTTP_GET="$commands[fetch] -qo - "

    elif [ -x "$commands[wget]" ]; then
        export HTTP_GET="$commands[wget] -qO -"

    elif [ -x "$commands[http]" ]; then
        export HTTP_GET="$commands[http] -FISb"

    elif [ -x "$commands[curl]" ]; then
        export HTTP_GET="$commands[curl] -fsSL"
    else
        fail $0 "curl, wget, fetch or httpie isn't exists"
    fi


    if [ -x "$commands[zstd]" ]; then
        export ASH_PAQ="$commands[zstd] -0 -T0"
        export ASH_QAP="$commands[zstd] -qd"

    elif [ -x "$commands[lz4]" ]; then
        export ASH_PAQ="$commands[lz4] -1 - -"
        export ASH_QAP="$commands[lz4] -d - -"

    elif [ -x "$commands[xz]" ] && [ -x "$commands[xzcat]" ]; then
        export ASH_PAQ="$commands[xz] -0 -T0"
        export ASH_QAP="$commands[xzcat]"

    elif [ -x "$commands[gzip]" ] && [ -x "$commands[zcat]" ]; then
        export ASH_PAQ="$commands[gzip] -1"
        export ASH_QAP="$commands[zcat]"

    else
        unset ASH_PAQ
        unset ASH_QAP
    fi


    function fs.size {
        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
            return 1
        fi

        builtin zstat -LA result "$1" 2>/dev/null
        [ "$?" -eq 0 ] && echo "$result[8]"
    }

    function fs.mtime {
        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
            return 1
        fi

        builtin zstat -LA result "$1" 2>/dev/null
        [ "$?" -eq 0 ] && echo "$result[10]"
    }

    function fs.readlink {
        if [ -z "$1" ]; then
            fail $0 "call without args, I need to do — what?"
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
        fail $0 "resolver isn't configured, need realpath or readlink"
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
            fail $0 "'$link' doesn't exist"
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
            warn $0 "can't make real home path for HOME '$home', REAL '$(which realpath)', READLINK '$(which readlink)', fallback '$(fs.dirname "$home")/$(fs.basename "$home")'"
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
                fail $0 "link source '$1' -> '$dst' isn't executable (exists?)"
                return 2
            fi

        else
            if [[ "$1" =~ "/" ]]; then
                fail $0 "link source '$1' couldn't contains slashes"
                return 1
            fi
            local src="$dir/$1"
            local dst="$2"

            if [ ! -x "$dst" ]; then
                fail $0 "link source '$2' -> '$dst' isn't executable (exists?)"
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


    if [ -z "$ASH" ] || [ -z "$ZSH" ] || [ -z "$ASH_CACHE" ] || [ "$INSTALL" -gt 0 ]; then
        local redirect="$(fs.home)"
        if [ -x "$redirect" ] && [ ! "$redirect" = "$HOME" ]; then
            if [ "$(fs.realpath "$redirect")" != "$(fs.realpath "$HOME")" ]; then
                warn $0 "HOME:'$HOME' -> '$redirect'"
            fi
            export HOME="$redirect"
        fi

        export ASH="${ASH:-$HOME/.ash}"
        export PATH="$ASH/bin:$PATH"
        export ASH_CACHE="$HOME/.cache/ash"

        [ ! -d "$ASH_CACHE" ] && mkdir -p "$ASH_CACHE"

        if [[ "$ZSH" =~ '/.josh$' ]] && [ -d "$HOME/.oh-my-zsh" ]; then
            export ZSH="$HOME/.oh-my-zsh"

        elif [[ "$ZSH" =~ '/.josh$' ]] && [ "$INSTALL" -gt 0 ]; then
            export ZSH="$HOME/.oh-my-zsh"

        else
            export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
            [ ! -d "$ZSH" ] && fail $0 "oh-my-zsh dir \$ZSH:'$ZSH' doesn't exists"
        fi

    fi

    function fs.lookup.missing {
        local missing=""
        for bin in $(echo "$*" | sed -re 's#\s+#\n#g' | sort -u); do
            if [ ! -x "$commands[$bin]" ] && [ ! -x "$(builtin which -p "$bin" 2>/dev/null)" ]; then
                if [ -z "$missing" ]; then
                    local missing="$bin"
                else
                    local missing="$missing $bin"
                fi
            fi
        done
        if [ -n "$missing" ]; then
            echo "$missing"
        else
            return 1
        fi
    }

    function fs.dirs.normalize {
        local result=''
        for dir in $*; do
            local dir="$($SHELL -c "echo $dir" 2>/dev/null)"
            if [ -n "$dir" ] && [ -d "$dir" ]; then
                local dir="$(realpath "$dir")"
                if [ -n "$dir" ] && [ -d "$dir" ]; then
                    if [ -z "$result" ]; then
                        local result="$dir"
                    else
                        local result="$result:$dir"
                    fi
                fi
            fi
        done
        echo "$result"
    }

    function escape.regex {
        echo "$(printf '%s' "$1" | sed 's/[.[\(*^$+?{|]/\\&/g')"
    }

    function fs.dirs.exclude {
        local regex="^`echo "$(escape.regex "$2")" | sed "s#:#|^#g"`"

        for dir in $(echo "$1" | sed 's#:#\n#g'); do
            if [ -z "$dir" ]; then
                continue
            fi

            local dir="$(fs.realpath "$dir" 2>/dev/null)"
            if [ -z "$dir" ]; then
                continue
            fi

            if [ -n "$(echo "$dir" | grep -Po "$regex")" ]; then
                continue
            fi

            if [ -n "$dir" ] && [ -d "$dir" ]; then
                if [ -z "$result" ]; then
                    local result="\"$dir\""
                else
                    local result="$result \"$dir\""
                fi
            fi
        done
        echo "$result"
    }

    function lookup.many {
        local dirs="${@:2}"
        if [ -z "$dirs" ]; then
            local dirs="$path"
        fi
        local cmd="fd --unrestricted --case-sensitive --max-depth 1 --type executable --type symlink -- \"^$1$\" $dirs"
        eval {$cmd} 2>/dev/null
    }

    function lookup.copies.cached {
        local expire="$2"

        local ignore="$(
            eval.cached "$expire" fs.dirs.normalize ${@:3})"

        local directories="$(
            eval.cached "$expire" fs.dirs.exclude "$PATH" "$ignore")"

        local result="$(
            eval.cached "$expire" lookup.many "$1" $directories)"

        echo "$result"
    }

    function fs.lm.many {
        if [ -n "$*" ]; then
            local result="$(
                builtin zstat -L `echo "$*" | sed -re 's#:# #g' | sed -re 's#\n# #g'` 2>/dev/null | \
                grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
            )"
            echo "$result"
        fi
    }

    function path.clean.uncached {
        if [ ! -x "$ASH" ]; then
            term $0 "something went wrong, ASH path empty"
            return 1
        fi

        local unified_path

        unified_path="$(
            echo "$*" | sed 's#:#\n#g' | sed "s:^~/:$HOME/:" | \
            xargs -n 1 realpath 2>/dev/null | awk '!x[$0]++' | \
            grep -v "$ASH" | \
            sed -z 's#\n#:#g' | sed 's#:$##g')" || return "$?"

        if [ -z "$unified_path" ]; then
            return 255
        fi

        local found=""
        local result=""
        local pattern="^$HOME/.python"
        for dir in $(echo "$unified_path" | sed 's#:#\n#g'); do

            if [[ "$dir" -regex-match $pattern ]]; then
                if [ -z "$found" ]; then
                    local found="$dir"
                else
                    continue
                fi
            fi

            if [ -z "$result" ]; then
                local result="$dir"
            else
                local result="$result:$dir"
            fi
        done

        if [ -z "$result" ]; then
            fail $0 "something went wrong: $path"
            return 127
        fi
        echo "$result"
    }

    function fs.path.fix {
        if [ ! -x "$ASH" ]; then
            term $0 "something went wrong, ASH path empty"
            return 1
        fi

        rehash
        for key link in ${(kv)commands}; do
            if [[ "$link" -regex-match "^$ASH" ]] && [ ! -x "$link" ]; then
                local dir="$(fs.dirname $link)"
                if [ -w "$dir" ]; then
                    local bin="$(builtin which -p "$key")"
                    if [ -x "$bin" ]; then
                        warn $0 "broken link '$link', relink '$key' -> '$bin'"
                        unlink "$link" && fs.link "$bin" >/dev/null
                    else
                        warn $0 "broken link '$link', missing binary '$key', unlink"
                        unlink "$link"
                        unset "commands[$key]"
                    fi
                fi
            fi
        done
    }

    function path.rehash {
        if [ ! -x "$ASH" ]; then
            term $0 "something went wrong, ASH path empty"
            return 1
        fi

        local result
        result="$(eval.cached "$(fs.lm.many $path)" path.clean.uncached "$path")"
        local retval="$?"

        if [ "$retval" -eq 0 ] || [ -n "$result" ]; then
            export PATH="$ASH/bin:$result"
            fs.path.fix
        fi
        return "$retval"
    }

    function temp.dir {
        local result="$(fs.dirname `mktemp -duq`)"
        [ ! -x "$result" ] && mkdir -p "$result"
        echo "$result"
    }

    function temp.file {
        local dir="$(temp.dir)"
        if [ ! -x "$dir" ]; then
            return 1
        elif [ -z "$ASH_MD5_PIPE" ]; then
            return 2
        fi

        local dst="$dir/$(echo "$USER $HOME $EPOCHSECONDS $$ $*" | sh -c "$ASH_MD5_PIPE").$USER.$$.tmp"
        touch "$dst" 2>/dev/null
        if [ "$?" -gt 0 ]; then
            return 3
        fi

        unlink "$dst" 2>/dev/null
        echo "$dst"
    }

    function eval.run {
        local cmd="$*"
        eval ${cmd}
        local retval="$?"
        return "$retval"
    }

    function eval.cached {
        local result

        if [ -z "$1" ]; then
            fail $0 "\$1 expire must be: '$1' '${@:2}'"
            return 1

        elif [ -z "$2" ]; then
            fail $0 "\$2.. command line empty: '$1' '${@:2}'"
            return 2

        elif [ -z "$ASH_MD5_PIPE" ] || [ -z "$ASH_PAQ" ] || [ -z "$ASH_QAP" ]; then
            warn $0 "cache doesnt't works, check ASH_MD5_PIPE '$ASH_MD5_PIPE', ASH_PAQ '$ASH_PAQ', ASH_QAP '$ASH_QAP'"
            local command="${@:2}"
            eval ${command}
            local retval="$?"
            return "$retval"
        fi

        if [ -z "$ASH_CACHE" ]; then
            term $0 "\$ASH_CACHE:'$ASH_CACHE' - what a fuck?"
            return 127
        fi

        if [[ "$1" -regex-match '^[0-9]+' ]]; then
            local expires="$MATCH"
        else
            local expires="$1"
        fi

        let expires="$expires"
        if [ "$expires" -eq 0 ]; then
            let expires="1"
        fi

        let relative="$expires < 1000000000"
        if [ "$relative" -gt 0 ]; then
            let expires="$EPOCHSECONDS - $expires"
        fi

        unset cache
        local body="$(builtin which "$2")"

        if [[ ! "$body" -regex-match 'not found$' ]] && [[ "$body" -regex-match "$2 \(\) \{" ]]; then
            local body="$(eval "builtin which '$2' | $ASH_MD5_PIPE" | cut -c -16)"
            local args="$(eval "echo '${@:3}' | $ASH_MD5_PIPE" | cut -c -16)"
            local cache="$ASH_CACHE/$body/$args"

            if [ -z "$args" ] || [ -z "$body" ]; then
                fail $0 "something went wrong for cache file '$cache', check ASH_MD5_PIPE '$ASH_MD5_PIPE'"
                return 3
            fi
        fi

        if [ -z "$cache" ]; then
            local func="$(builtin which -p "$2" 2>/dev/null)"

            if [ -x "$func" ]; then
                local body="$(eval "cat '$func' | $ASH_MD5_PIPE" | cut -c -16)"
                local args="$(eval "echo '${@:3}' | $ASH_MD5_PIPE" | cut -c -16)"
                local cache="$ASH_CACHE/$body/$args"
            fi
        fi

        if [ -z "$cache" ]; then
            local args="$(eval "echo '${@:2}' | $ASH_MD5_PIPE" | cut -c -32)"
            local cache="$ASH_CACHE/.pipelines/$args"

            if [ -z "$args" ]; then
                fail $0 "something went wrong for cache file '$cache', check ASH_MD5_PIPE '$ASH_MD5_PIPE'"
                return 4
            fi
        fi


        if [ -z "$cache" ]; then
            fail $0 "something went wrong: '$1' '${@:2}'"
        fi

        if [ "$DO_NOT_READ" -gt 0 ] || [ ! -f "$cache" ]; then
            let expired="1"
        else
            local last_update="$(fs.mtime $cache 2>/dev/null)"
            [ -z "$last_update" ] && local last_update="0"
            let expired="$expires > $last_update"
        fi

        local subdir="$(fs.dirname "$cache")"
        if [ ! -d "$subdir" ]; then
            mkdir -p "$subdir"
        fi

        if [ -z "$BINARY_SAFE" ]; then
            if [ "$expired" -eq 0 ]; then
                result="$(eval.run "cat '$cache' | $ASH_QAP 2>/dev/null")"
                local retval="$?"

                if [ "$retval" -eq 0 ]; then
                    echo "$result"
                    return 0
                fi
            fi

            if [ "$DO_NOT_RUN" -gt 0 ]; then
                return 255
            fi

            result="$(eval.run ${@:2})"
            local retval="$?"

            if [ "$retval" -eq 0 ]; then
                eval {"echo '$result' | $ASH_PAQ > '$cache'"}
                echo "$result"
            fi
            return "$retval"
        else

            local dir="$(temp.dir)"
            if [ ! -x "$dir" ]; then
                return 1
            elif [ -z "$ASH_MD5_PIPE" ]; then
                return 2
            fi

            local tempfile
            tempfile="$(temp.file "$*")"
            if [ "$?" -gt 0 ] || [ -z "$tempfile" ]; then
                return 3
            fi

            if [ "$expired" -eq 0 ]; then
                local cmd="cat '$cache' | $ASH_QAP 2>/dev/null >'$tempfile'"
                eval ${cmd} >/dev/null
                local retval="$?"
                if [ "$retval" -eq 0 ]; then
                    cat "$tempfile"
                    unlink "$tempfile"
                    return 0
                fi
            fi

            if [ "$DO_NOT_RUN" -gt 0 ]; then
                unlink "$tempfile" 2>/dev/null
                return 255
            fi

            eval.run ${@:2} >$tempfile
            local retval="$?"

            if [ "$retval" -eq 0 ]; then
                cat "$tempfile"
                local cmd="cat '$tempfile' | $ASH_PAQ >'$cache'"
                eval ${cmd}
            fi
            unlink "$tempfile"
            return "$retval"
        fi
    }

    function run_show {
        local cmd="$*"
        [ -z "$cmd" ] && return 1
        echo " -> $cmd" 1>&2
        eval ${cmd} 1>&2
    }

    function run_silent {
        local cmd="$*"
        [ -z "$cmd" ] && return 1
        echo " -> $cmd" 1>&2
        eval ${cmd} 1>/dev/null 2>/dev/null
    }

    function run_to_stdout {
        local cmd="$*"
        [ -z "$cmd" ] && return 1
        eval ${cmd} 2>&1
    }

    function run_hide {
        local cmd="$*"
        [ -z "$cmd" ] && return 1
        eval ${cmd} 1>/dev/null 2>/dev/null
    }

    function fs.lm {
        local args="$*"
        [ -x "$1" ] && local args="$(fs.realpath "$1") ${@:2}"
        local cmd="find $args -printf \"%T@ %p\n\" | sort -n | tail -n 1"
        eval ${cmd}
    }

    function fs.lm.dirs {
        local args="$*"
        [ -x "$1" ] && local args="$(fs.realpath "$1") ${@:2}"
        local cmd="find $args -type d -not -path '*/.git*' -printf \"%T@ %p\n\" | sort -n | tail -n 1 | grep -Po '\d+' | head -n 1"
        eval ${cmd}
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
            fail $0 "call without args, I need to do — what?"
            return 2

        elif [[ "$src" =~ "/" ]]; then
            if [ -e "$src" ]; then
                echo "$src"
                return 0
            fi
            fail $0 "link name '$src' couldn't contains slashes"
            return 3

        elif [ -z "$ASH" ]; then
            warn $0 "root '$ASH' isn't defined"
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
                    warn $0 "'$src' isn't found, but $dst"
                    return 0
                fi
                return 1
            fi
        fi
        printf "$dst\n"
    }


    local osname="$(uname)"

    setopt no_case_match

    if [[ "$osname" -regex-match 'freebsd' ]]; then
        export ASH_OS="BSD"
        fs.link 'ls'    '/usr/local/bin/gnuls' >/dev/null
        fs.link 'grep'  '/usr/local/bin/grep'  >/dev/null

    elif [[ "$osname" -regex-match 'darwin' ]]; then
        export ASH_OS="MAC"
        fs.link 'ls'    '/usr/local/bin/gls'   >/dev/null
        fs.link 'grep'  '/usr/local/bin/ggrep' >/dev/null

        dirs=(
            bin
            sbin
            usr/bin
            usr/sbin
            usr/local/bin
            usr/local/sbin
        )

        for dir in $dirs; do
            if [ -d "/Library/Apple/$dir" ]; then
                export PATH="$PATH:/Library/Apple/$dir"
            fi
        done

    else
        if [[ "$osname" -regex-match 'linux' ]]; then
            export ASH_OS="LINUX"
        else
            fail $0 "unsupported OS '$(uname -srv)'"
            export ASH_OS="UNKNOWN"
        fi

        dirs=(
            bin
            sbin
            usr/bin
            usr/sbin
            usr/local/bin
            usr/local/sbin
        )

        for dir in $dirs; do
            if [ -d "/snap/$dir" ]; then
                export PATH="$PATH:/snap/$dir"
            fi
        done
    fi

    if [ "$ASH_OS" = 'BSD' ] || [ "$ASH_OS" = 'MAC' ]; then
        fs.link 'cut'       '/usr/local/bin/gcut'      >/dev/null
        fs.link 'find'      '/usr/local/bin/gfind'     >/dev/null
        fs.link 'head'      '/usr/local/bin/ghead'     >/dev/null
        fs.link 'readlink'  '/usr/local/bin/greadlink' >/dev/null
        fs.link 'realpath'  '/usr/local/bin/grealpath' >/dev/null
        fs.link 'sed'       '/usr/local/bin/gsed'      >/dev/null
        fs.link 'tail'      '/usr/local/bin/gtail'     >/dev/null
        fs.link 'tar'       '/usr/local/bin/gtar'      >/dev/null
        fs.link 'xargs'     '/usr/local/bin/gxargs'    >/dev/null
        export ASH_MD5_PIPE="$(which md5)"
    else
        export ASH_MD5_PIPE="$(which md5sum) | $(which cut) -c -32"
    fi

    local gsed="$(which gsed)"
    if [ ! -x "$gsed" ]; then
        local gsed="$(which sed)"
    fi
    alias sed="$gsed"

    local perm_path_regex="$(echo "$perm_path" | sed 's:^:^:' | sed 's: *$:/:' | sed 's: :/|^:g')"

    function lookup {
        for sub in $path; do
            if [ -x "$sub/$1" ]; then
                echo "$sub/$1"
                [ -z "$2" ] && return 0
            fi
        done
    }

    if [[ -n ${(M)zsh_eval_context:#file} ]]; then
        local THIS_SOURCE="$(fs.gethash "$0")"
        if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
            SOURCES_CACHE+=("$THIS_SOURCE")

            if [ -n "$ASH" ] && [ ! -d "$ASH" ]; then
                fail "$0" "running Ash in old Josh context, force redeploy"
                git clone --branch develop --single-branch 'https://github.com/kalaverin/Josh.git' "$ASH" && \
                INSTALL=1 zsh "$ASH/run/init.sh"
            fi
        fi
    else

        fail $0 "do not run or eval, just source it"
        return 2
    fi
fi
