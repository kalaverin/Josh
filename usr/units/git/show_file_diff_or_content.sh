result="$(git diff --color=always --patch -R "$1" -- "$2" 2>&1)"

if [ -z "$result" ] && [ -f "$2" ]; then
    result="$(bat --force-colorization --file-name "$2" "$2" 2>&1)"
fi
printf "%s" $result
