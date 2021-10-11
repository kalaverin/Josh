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
            fi
        done
    }

    function path_last_modified() {
       local result="$(
            builtin zstat -L `echo "$PATH" | tr ':' ' ' ` 2>/dev/null | \
            grep mtime | awk -F ' ' '{print $2}' | sort -n | tail -n 1 \
        )"
        echo "$result"
    }

    function pathprune() {
        local unified_path="$(
            echo "$path" | sed 's#:#\n#' | sed "s:^~/:$HOME/:" | \
            xargs -n 1 realpath 2>/dev/null | awk '!x[$0]++' | \
            grep -v "$JOSH" | \
            sed -z 's#\n#:#g' | sed 's#:$##g' \
        )"

        local ret="$?"
        if [ "$ret" -eq 0 ] && [ -n "$unified_path" ]; then
            if [ "$1" = 'links' ]; then
                export PATH="$unified_path"
            else
                export PATH="$JOSH/bin:$unified_path"
            fi
        fi
        return "$ret"
    }
fi
