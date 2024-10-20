result="$(git diff "$1" 2>&1)"
if [ -z "$result" ]; then
    result="$(git show "$1" 2>&1)"
fi
printf "%s" $result
