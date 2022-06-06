[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)

local source_file="$(fs_joshpath "$0")"
if [ -n "$source_file" ] && [[ "${sourced[(Ie)$source_file]}" -eq 0 ]]; then
    sourced+=("$source_file")

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

            local dir="$(fs_realpath "$dir" 2>/dev/null)"
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
            cached_execute "$0" "$expire" "$JOSH_CACHE_DIR" \
            "fs.dirs.normalize" ${@:3})"

        local directories="$(
            cached_execute "$0" "$expire" "$JOSH_CACHE_DIR" \
            "fs.dirs.exclude" "$PATH" "$ignore")"

        local result="$(
            cached_execute "$0" "$expire" "$JOSH_CACHE_DIR" \
            "lookup.many" "$1" $directories)"

        echo "$result"
    }

    function path_last_modified {
        if [ -n "$*" ]; then
            local result="$(
                builtin zstat -L `echo "$1" | tr ':' ' '` 2>/dev/null | \
                grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
            )"
            echo "$result"
        fi
    }

    function path_prune {
        local unified_path="$(
            echo "$path" | sed 's#:#\n#g' | sed "s:^~/:$HOME/:" | \
            xargs -n 1 realpath 2>/dev/null | awk '!x[$0]++' | \
            grep -v "$JOSH" | \
            sed -z 's#\n#:#g' | sed 's#:$##g')"
        local retval="$?"

        if [ "$retval" -eq 0 ] && [ -n "$unified_path" ]; then

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
                printf " ** fail ($0): something went wrong: $path\n" >&2
                return 1
            else
                export PATH="$result"
                if [ ! "$1" = 'links' ]; then
                    export PATH="$JOSH/bin:$result"
                fi
            fi
        fi
        rehash
        return "$retval"
    }

    function cached_execute {
        if [ -z "$1" ]; then
            printf " ** fail ($0): \$1 key must be: '$1' '$2' '$3' '${@:4}'\n" >&2
            return 1

        elif [ -z "$2" ]; then
            printf " ** fail ($0): \$2 expire must be: '$1' '$2' '$3' '${@:4}'\n" >&2
            return 2

        elif [ -z "$3" ]; then
            printf " ** fail ($0): \$3 cache dir must be: '$1' '$2' '$3' '${@:4}'\n" >&2
            return 3

        elif [ -z "$4" ]; then
            printf " ** fail ($0): args one or many must be: '$1' '$2' '$3' '${@:4}'\n" >&2
            return 4

        elif [ -z "$JOSH_MD5_PIPE" ] || [ -z "$JOSH_PAQ" ] || [ -z "$JOSH_QAP" ]; then
            printf " ++ warn ($0): cache doesnt't works, check JOSH_MD5_PIPE '$JOSH_MD5_PIPE', JOSH_PAQ '$JOSH_PAQ', JOSH_QAP '$JOSH_QAP'\n" >&2
            local command="${@:4}"
            eval ${command}
            local retval="$?"
            return "$retval"
        fi

        let expires="$2"
        if [ "$expires" -eq 0 ]; then
            let expires="1"
        fi

        let relative="$expires < 1000000000"
        if [ "$relative" -gt 0 ]; then
            let expires="$EPOCHSECONDS - $expires"
        fi

        echo "eval \"builtin which '$1' | $JOSH_MD5_PIPE\"" >&2
        echo "eval \"builtin which '$4' 2>/dev/null| $JOSH_MD5_PIPE\"" >&2

        local call="$(eval "builtin which '$1' | $JOSH_MD5_PIPE | cut -c -4")"
        local body="$(eval "builtin which '$4' 2>/dev/null | $JOSH_MD5_PIPE | cut -c -4")"

        local name="$(eval "echo "$1" | $JOSH_MD5_PIPE")"
        local args="$(eval "echo "${@:4}" | $JOSH_MD5_PIPE")"
        local file="$3/$name/$args.$call$body"

        if [ -z "$body" ] || [ -z "$call" ] || [ -z "$name" ] || [ -z "$args" ]; then
            printf " ** fail ($0): something went wrong for cache file '$file', check JOSH_MD5_PIPE '$JOSH_MD5_PIPE'\n" >&2
            return 5
        fi

        if [ ! -f "$file" ]; then
            let expired="1"
        else
            local last_update="$(fs_mtime $file 2>/dev/null)"
            [ -z "$last_update" ] && local last_update="0"
            let expired="$expires > $last_update"
        fi

        local subdir="$(fs_dirname "$file")"
        if [ ! -d "$subdir" ]; then
            mkdir -p "$subdir"
        fi

        if [ "$expired" -eq 0 ]; then
            local result="$(eval.retval "cat '$file' | $JOSH_QAP 2>/dev/null")"
            local retval="$?"

            if [ ! "$retval" -gt 0 ]; then
                echo "$result"
                return 0
            fi
        fi


        local result="$(eval.retval ${@:4})"
        local retval="$?"

        if [ "$retval" -eq 0 ]; then
            eval {"echo '$result' | $JOSH_PAQ > '$file'"}
            echo "$result"
        fi
        return "$retval"
    }
fi
