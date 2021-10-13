source "$JOSH/lib/shared.sh"

function bak {
    if [ -f "$BAK_RESTORE" ]; then
        echo " * backup already found: $BAK_RESTORE"
        return 1
    fi
    local last_path="`pwd`"

    mktp
    [ "$?" -gt 0 ] && return 1

    local temp_path="`pwd`"
    builtin cd $last_path

    local dir_name=`fs_basename "$last_path"`
    [ "$?" -gt 0 ] && return 2

    local threads_count="`cpu_cores_count`"
    [ "$?" -gt 0 ] && return 3

    local backup="$temp_path/$dir_name.tar.xz"
    run_show "tar -cO --exclude-vcs . | xz -1 -T$threads_count > $backup"
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
        local cmd="$exe $backup && $exe `fs_dirname $backup`"
    else
        local cmd="rm $backup && rm -r `fs_dirname $backup`"
    fi

    run_show "$cmd"
    export BAK_RESTORE=""
}
