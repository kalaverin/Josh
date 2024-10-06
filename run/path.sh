cleaned_path=()
for dir in $path; do
    local dir="${dir//\*/ }"

    if [[ "$dir" -regex-match "^/mnt/" ]] || [ ! -d "$dir" ]  || [ ! -x "$dir" ]; then
        continue
    fi

    cleaned_path+="$dir"
done

perm_path=(
    $HOME/.cargo/bin
)

if [ -n "$VIRTUAL_ENV" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    perm_path=(
        $perm_path
        $VIRTUAL_ENV/bin
    )
fi

if [ -n "$PYROOT" ] && [ -d "$PYROOT/bin" ]; then
    perm_path=(
        $perm_path
        $PYROOT/bin
    )
else
    perm_path=(
        $perm_path
        $HOME/.py/default/bin
    )
fi

perm_path=(
    $perm_path
    $ASH/bin
    $HOME/.local/bin
    $HOME/.go/bin
    $HOME/bin
    $HOME/.ruby/bin
    /usr/local/bin
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/sbin
    $HOME/go/bin
)

path=(
    $perm_path
    $cleaned_path
    $HOME/.brew/bin
)
