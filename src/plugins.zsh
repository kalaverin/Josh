function plugins_autoload {
    fd --no-ignore-vcs autoload.zsh "$JOSH/usr/local/" | while read loader
    do
        local loader="`fs_realpath $loader`"
        source "$loader"
    done
}
