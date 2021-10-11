[ -z "$sourced" ] && declare -aUg sourced=() && sourced+=($0)

local source_file="`fs_joshpath "$0"`"
if [ -n "$source_file" ] && [[ "${sourced[(Ie)$source_file]}" -eq 0 ]]; then
    sourced+=("$source_file")

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

    function shortcut() {
        [ -z "$ZSH" ] || [ -z "$1" ] && return 0

        if [ -z "$2" ]; then
            if [ -x "$JOSH/bin/$1" ]; then
                local dst="`fs_readlink "$JOSH/bin/$1"`"
                if [ -x "$dst" ]; then
                    echo "$dst"
                    return 0
                fi
                return 2
            fi
            return 1

        else
            if [ ! -x "$2" ]; then
                return 1
            elif [[ "$1" =~ "/" ]]; then
                return 2
            fi

            local dir="$JOSH/bin"
            local src="$dir/$1"

            local dst="`fs_realpath $2`"
            if [ -z "$dst" ] || [ ! -x "$dst" ]; then
                return 3
            fi

            # if link already exists we need to check link destination
            if [ -L "$src" ] && [ ! "$dst" = "`fs_realpath "$src"`" ]; then
                unlink "$src"
            fi

            if [ ! -f "$src" ]; then
                [ ! -d "$dir" ] && mkdir -p "$dir"
                ln -s "$dst" "$src"
            fi
            echo "$dst"
        fi
    }

    function which() {
        if [[ "$1" =~ "/" ]]; then
            if [ -x "$1" ]; then
                if [ -L "$1" ]; then
                    local dst="`fs_readlink "$1"`"
                    if [ -x "$dst" ]; then
                        echo "$dst"
                        return 0
                    fi
                    return 1

                else
                    echo "$1"
                    return 0

                fi
            fi
        fi

        if [ -L "$JOSH/bin/$1" ]; then
            local dst="`fs_readlink "$JOSH/bin/$1"`"
        elif [ -x "$commands[$1]" ]; then
            local dst="$commands[$1]"
        fi

        if [ -x "$dst" ]; then
            echo "$dst"
            return 0
        fi
    }
fi
