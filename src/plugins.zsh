function plugins_autoload {
    fd --no-ignore-vcs autoload.zsh$ "$ASH/usr/local/" | while read loader
    do
        local loader="$(fs.realpath $loader)"
        source "$loader"
        local retval="$?"

        if [ "$retval" -gt 0 ]; then
            fail $0 "something went wrong with '$(fs.dirname $loader)', code: $retval"
        fi
    done
}
