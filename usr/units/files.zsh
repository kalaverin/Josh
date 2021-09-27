. $JOSH/lib/shared.sh

function bak {
    if [ -f "$BAK_RESTORE" ]; then
        echo " * backup already found: $BAK_RESTORE"
        return 1
    fi

    local last_path="`pwd`"
    mktp
    local temp_path="`pwd`"
    builtin cd $last_path

    local dir_name=`basename "$last_path"`
    local backup="$temp_path/$dir_name.tar.xz"

    cpu_count
    run_show "tar -cO --exclude-vcs . | xz -1 -T$? > $backup"
    echo " => xzcat $backup | tar -x"
    export BAK_RESTORE="$backup"
}

function kab {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        echo " * backup path isn't set"
        return 1
    fi

    is_repository_clean
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

    if [ -x "`lookup rip`" ]; then
        local exe="`lookup rip`"
        local cmd="$exe $backup && $exe `dirname $backup`"
    else
        local cmd="rm $backup && rm -r `dirname $backup`"
    fi

    run_show "$cmd"
    export BAK_RESTORE=""
}
