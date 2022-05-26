[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)

local source_file="`fs_joshpath "$0"`"
if [ -n "$source_file" ] && [[ "${sourced[(Ie)$source_file]}" -eq 0 ]]; then
    sourced+=("$source_file")

    alias sed="`which sed`"

    local perm_path_regex="`echo "$perm_path" | sed 's:^:^:' | sed 's: *$:/:' | sed 's: :/|^:g'`"

    function lookup() {
        for sub in $path; do
            if [ -x "$sub/$1" ]; then
                echo "$sub/$1"
                return 0
            fi
        done
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

            local dir="$(realpath "$dir")"
            if [ -z "$dir" ]; then
                continue
            fi

            if [ -n "$(echo "$dir" | grep -Po "$regex")" ]; then
                continue
            fi

            if [ -n "$dir" ] && [ -d "$dir" ]; then
                if [ -z "$result" ]; then
                    local result="$dir"
                else
                    local result="$result:$dir"
                fi
            fi
        done
        echo "$result"
    }

    function lookup.all() {
        local ignore="$(
            cached_execute "$0" "$2" "$JOSH_CACHE_DIR" \
            "fs.dirs.normalize" ${@:3})"

        local directories="$(
            cached_execute "$0" "$2" "$JOSH_CACHE_DIR" \
            "fs.dirs.exclude" "$PATH" "$ignore")"

        local result=''
        for dir in $(echo "$directories" | sed 's#:#\n#g'); do
            local bin="$dir/$1"
            if [ -x "$bin" ] || [ -L "$bin" ]; then
                if [ -z "$result" ]; then
                    local result="$bin"
                else
                    local result="$result:$bin"
                fi
            fi
        done
        echo "$result"
    }

    function path_last_modified() {
        if [ -n "$*" ]; then
            local result="$(
                builtin zstat -L `echo "$1" | tr ':' ' ' ` 2>/dev/null | \
                grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
            )"
            echo "$result"
        fi
    }

    function path_prune() {
        local unified_path="$(
            echo "$path" | sed 's#:#\n#' | sed "s:^~/:$HOME/:" | \
            xargs -n 1 realpath 2>/dev/null | awk '!x[$0]++' | \
            grep -v "$JOSH" | \
            sed -z 's#\n#:#g' | sed 's#:$##g' \
        )"

        local ret="$?"
        if [ "$ret" -eq 0 ] && [ -n "$unified_path" ]; then
            export PATH="$unified_path"
            if [ ! "$1" = 'links' ]; then
                export PATH="$JOSH/bin:$unified_path"
            fi
        fi
        return "$ret"
    }

    function cached_execute() {
        if [ -z "$1" ]; then
            echo " - fatal $0: \$1 key must be: \`$1\`, \`$2\`, \`$3\`, \`${@:4}\` " >&2
            return 1

        elif [ -z "$2" ]; then
            echo " - fatal $0: \$2 expire must be: \`$1\`, \`$2\`, \`$3\`, \`${@:4}\` " >&2
            return 2

        elif [ -z "$3" ]; then
            echo " - fatal $0: \$3 cache dir must be: \`$1\`, \`$2\`, \`$3\`, \`${@:4}\` " >&2
            return 3

        elif [ -z "$4" ]; then
            echo " - fatal $0: args one or many must be: \`$1\`, \`$2\`, \`$3\`, \`${@:4}\` " >&2
            return 4
        fi

        if [ -z "$JOSH_MD5_PIPE" ] || [ -z "$JOSH_QAP" ] || [ -z "$JOSH_QAP" ]; then
            local command="${@:4}"
            local result="`eval ${command}`"
            local retval="$?"
            echo "$result"
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

        local f1="`eval "echo "$1" | $JOSH_MD5_PIPE"`"
        local f2="`eval "echo "${@:4}" | $JOSH_MD5_PIPE"`"
        local file="$3/$f1/$f2"

        if [ ! -f "$file" ]; then
            let expired="1"
        else
            local last_update="`fs_mtime $file 2>/dev/null`"
            [ -z "$last_update" ] && local last_update="0"
            let expired="$expires > $last_update"
        fi

        if [ "$expired" -eq 0 ]; then
            local command="cat \"$file\" | $JOSH_QAP"
            local result="`eval ${command}`"
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
        fi

        local result="`eval ${@:4}`"
        local retval="$?"

        if [ -n "$result" ] && [ "$retval" -eq 0 ]; then
            if [ ! -d "`fs_dirname "$file"`" ]; then
                mkdir -p "`fs_dirname "$file"`"
            fi
            local command="echo \"$result\" | $JOSH_PAQ > \"$file\""
            eval ${command}
        fi
        echo "$result"
        return "$retval"
    }
fi
