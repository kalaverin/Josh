source "$JOSH/lib/shared.sh"

function bak {
    if [ -f "$BAK_RESTORE" ]; then
        echo " * backup already found: $BAK_RESTORE"
        return 1
    fi

    local root="`git_root`"
    [ -z "$root" ] && local root="$PWD"

    local source="`fs_basename "$root"`"
    [ "$?" -gt 0 ] && return 1

    local timemark="`date "+%Y.%m.%d"`"
    [ "$?" -gt 0 ] && return 2

    local target="`get_tempdir`/baks/$source"
    [ "$?" -gt 0 ] && return 3

    local backup="$target/$timemark-`make_human_name`.tar"
    [ "$?" -gt 0 ] && return 4

    local threads_count="`cpu_cores_count`"
    [ "$?" -gt 0 ] && local threads_count="0"

    run_show "mkdir -p \"$target\" 2>/dev/null; tar -cO --exclude-vcs . | xz -1 -T$threads_count > $backup"
    echo " => xzcat $backup | tar -x"
    export BAK_RESTORE="$backup"
}

function kab {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        echo " * backup path isn't set"
        return 1
    fi

    git_repository_clean
    if [ $? -gt 0 ]; then
        return 1
    fi

    run_show "xzcat $backup | tar -x"
    if [ $? -gt 0 ]; then
        return 1
    fi
}

function kabforce {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        echo " * backup path isn't set"
        return 1
    fi

    run_show "xzcat $backup | tar -x"
    if [ $? -gt 0 ]; then
        return 1
    fi
}

function bakrm {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        echo " * backup path isn't set"
        return 1
    fi

    if [ -x "`which rip`" ]; then
        local exe="`which rip`"
        local cmd="$exe $backup"
    else
        local cmd="rm $backup"
    fi

    run_show "$cmd"
    export BAK_RESTORE=""
}
