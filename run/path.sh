perm_path=(
    $HOME/.cargo/bin
)

if [ -n "$VIRTUAL_ENV" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    perm_path=(
        $perm_path
        $VIRTUAL_ENV/bin
    )
fi

if [ -n "$PYTHON" ] && [ -d "$PYTHON/bin" ]; then
    perm_path=(
        $perm_path
        $PYTHON/bin
    )
else
    perm_path=(
        $perm_path
        $HOME/.python/default/bin
    )
fi

perm_path=(
    $perm_path
    $HOME/.local/bin
    $HOME/bin
    /usr/local/bin
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/sbin
)

path=(
    $perm_path
    $path
    $HOME/.brew/bin
)
