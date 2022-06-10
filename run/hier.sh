[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

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

    function fs.lookup.missing {
        local missing=""
        for bin in $(echo "$*" | sd '\s+' '\n' | sort -u); do
            if [ ! -x "$commands[$bin]" ] && [ ! -x "$(which $bin 2>/dev/null)" ]; then
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
                builtin zstat -L `echo "$*" | sd ':' ' ' | sd '\n+' ' '` 2>/dev/null | \
                grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
            )"
            echo "$result"
        fi
    }

    function path.clean.uncached {
        local unified_path

        unified_path="$(
            echo "$*" | sed 's#:#\n#g' | sed "s:^~/:$HOME/:" | \
            xargs -n 1 realpath 2>/dev/null | awk '!x[$0]++' | \
            grep -v "$JOSH" | \
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

    function path.rehash {
        local result
        result="$(eval.cached "$(fs.lm.many $path)" path.clean.uncached "$path")"
        local retval="$?"

        if [ "$retval" -eq 0 ] || [ -n "$result" ]; then
            export PATH="$JOSH/bin:$result"
            rehash
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
        elif [ -z "$JOSH_MD5_PIPE" ]; then
            return 2
        fi

        local dst="$dir/$(echo "$USER $HOME $EPOCHSECONDS $$ $*" | sh -c "$JOSH_MD5_PIPE").$USER.$$.tmp"
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

        elif [ -z "$JOSH_MD5_PIPE" ] || [ -z "$JOSH_PAQ" ] || [ -z "$JOSH_QAP" ]; then
            warn $0 "cache doesnt't works, check JOSH_MD5_PIPE '$JOSH_MD5_PIPE', JOSH_PAQ '$JOSH_PAQ', JOSH_QAP '$JOSH_QAP'"
            local command="${@:2}"
            eval ${command}
            local retval="$?"
            return "$retval"
        fi

        let expires="$1"
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
            local args="$(eval "echo "${@:3}" | $JOSH_MD5_PIPE | cut -c -16")"
            local body="$(eval "builtin which "$2" | $JOSH_MD5_PIPE | cut -c -16")"
            local cache="$JOSH_CACHE_DIR/$body/$args"

            if [ -z "$args" ] || [ -z "$body" ]; then
                fail $0 "something went wrong for cache file '$cache', check JOSH_MD5_PIPE '$JOSH_MD5_PIPE'"
                return 3
            fi
        fi

        if [ -z "$cache" ]; then
            local func="$(builtin which -p "$2" 2>/dev/null)"

            if [ -x "$func" ]; then
                local args="$(eval "echo "${@:3}" | $JOSH_MD5_PIPE | cut -c -16")"
                local body="$(eval "cat "$func" | $JOSH_MD5_PIPE | cut -c -16")"
                local cache="$JOSH_CACHE_DIR/$body/$args"
            fi
        fi

        if [ -z "$cache" ]; then
            local args="$(eval "echo "${@:2}" | $JOSH_MD5_PIPE | cut -c -16")"
            local cache="$JOSH_CACHE_DIR/.pipelines/$args"

            if [ -z "$args" ]; then
                fail $0 "something went wrong for cache file '$cache', check JOSH_MD5_PIPE '$JOSH_MD5_PIPE'"
                return 4
            fi
        fi

        if [ -z "$cache" ]; then
            fail $0 "something went wrong: '$1' '${@:2}'"
        fi

        if [ ! -f "$cache" ]; then
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
                result="$(eval.run "cat '$cache' | $JOSH_QAP 2>/dev/null")"
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
                eval {"echo '$result' | $JOSH_PAQ > '$cache'"}
                echo "$result"
            fi
            return "$retval"
        else

            local dir="$(temp.dir)"
            if [ ! -x "$dir" ]; then
                return 1
            elif [ -z "$JOSH_MD5_PIPE" ]; then
                return 2
            fi

            local tempfile
            tempfile="$(temp.file "$*")"
            if [ "$?" -gt 0 ] || [ -z "$tempfile" ]; then
                return 3
            fi

            if [ "$expired" -eq 0 ]; then
                local cmd="cat '$cache' | $JOSH_QAP 2>/dev/null >'$tempfile'"
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
                local cmd="cat '$tempfile' | $JOSH_PAQ >'$cache'"
                eval ${cmd}
            fi
            unlink "$tempfile"
            return "$retval"
        fi
    }
fi
