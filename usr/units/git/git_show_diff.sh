if [ -f "$1" ]; then
    result="$(git diff "$1" 2>&1)"

    if [ -z "$result" ]; then
        result="$(git show "$1" 2>&1)"

        if [ -z "$result" ]; then
            result="$(bat --force-colorization "$1" 2>&1)"
        fi
    fi

else
    commit="$(git log --reverse --pretty=format:"%H" -- "$1" | head -n 1)"
    result="$(git show "$commit":"$1" 2>&1 | bat --force-colorization --file-name "$1")"

fi

printf "%s" "$result"
