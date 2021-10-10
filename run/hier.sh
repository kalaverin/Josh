echo "read $0"

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
                export PATH="$JOSH/sbin:$JOSH/bin:$unified_path"
            fi
        fi
        return "$ret"
    }

    function rehash() {
        [ -z "$JOSH" ] && return 1

        local venv="$VIRTUAL_ENV"
        if [ -n "$venv" ]; then
            source $venv/bin/activate && deactivate
        fi

        pathprune links
        builtin rehash


        let record=0
        typeset -Ag dirtimes

        if [ "$1" = 'force' ]; then
            local since=''
        else
            local since="`path_last_modified`"
        fi

        alias sed="`which sed`"
        builtin zstat -LnA link `find $JOSH/bin -type l | sed -z 's:\n: :g'`

        while true; do
            let name="$record * 15 + 1"
            [ -z "$link[$name]" ] && break

            let time="$record * 15 + 11"
            let node="$record * 15 + 15"
            let record="$record + 1"

            if [ "$1" = 'force' ]; then
                local expired=1

            else
                if [ "$since" -gt 0 ]; then
                    local dtime="$since"
                else
                    local key="`fs_dirname "$link[$node]"`"
                    local dtime="$dirtimes[$key]"
                    if [ -z "$dtime" ]; then
                        local dtime="`fs_mtime $key`"
                        dirtimes[$key]="$dtime"
                    fi
                fi
                let expired="$dtime > $link[$time]"
            fi

            local base="`fs_basename $link[$name]`"
            if [ "$expired" -gt 0 ]; then
                unlink "$link[$name]"
                shortcut "$base" "`which $commands[$base]`" 1>/dev/null

            else
                local node="`fs_basename $link[$node]`"

                if [ ! "$base" = "$node" ]; then
                    shortcut "$base" "`which $commands[$base]`" 1>/dev/null
                fi
            fi

        done

        pathprune
        [ -n "$venv" ] && source "$venv/bin/activate"
        builtin rehash
    }

    function shortcut() {
        [ -z "$ZSH" ] || [ -z "$1" ] && return 0
        [[ "$1" =~ "/" ]] && return 1

        if [ -z "$2" ]; then
            local order=( "$JOSH/sbin" "$JOSH/bin" )
            for dir in $order; do
                if [ ! -d "$dir" ]; then
                    mkdir -p "$dir"
                    continue
                fi

                local src="$dir/$1"
                if [ -L "$src" ]; then
                    local dst="`fs_realpath "$src"`"
                    if [ -x "$dst" ]; then
                        echo "$1 $dst"
                        return 0
                    fi
                fi
            done
            return 1

        else
            if [ ! -x "$2" ]; then
                return 2
            fi

            if [ "$3" = 'permanent' ]; then
                local dir="$JOSH/sbin"
            else
                local dir="$JOSH/bin"
            fi

            local src="$dir/$1"
            local dst="`fs_realpath $2`"
            if [ -z "$dst" ] || [ ! -x "$dst" ]; then
                return 3
            fi

            if [ ! "$3" = 'permanent' ] && [[ ! "$dst" =~ "$perm_path_regex" ]]; then
                echo "$dst"
                return 0
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
            if [ -x "$1" ] && [ ! -L "$1" ]; then
                local short="`fs_basename "$1"`"
                if [ ! -L "$JOSH/bin/$short" ]; then
                    shortcut "$short" "$1"
                fi
                echo "$1"
                return 0

            else
                echo "`fs_realpath "$1"`"
                return "$?"
            fi
        fi

        if [ -n "$VIRTUAL_ENV" ]; then
            result="`builtin which "$1" 2>/dev/null`"
            if [ -x "$result" ]; then
                echo "$result"
                return "$?"
            fi
        fi

        local node="`shortcut "$1"`"
        if [ -x "$node" ]; then
            echo "$node"
            return 0

        else
            local node="`shortcut "$1" "$commands[$1]"`"
            if [ -n "$node" ]; then
                echo "$node"
                return "$?"
            fi
        fi
    }
fi
