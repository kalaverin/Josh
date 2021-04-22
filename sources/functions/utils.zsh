function bak {
    if [ "$BAK_RESTORE" != "" ]; then
        echo " * backup already found: $BAK_RESTORE"
        return 1
    fi

    local last_path="`pwd`"
    mktp
    local temp_path="`pwd`"
    cd $last_path

    local dir_name=`basename "$last_path"`
    local backup="$temp_path/$dir_name.tar.xz"

    run_show "tar -cO --exclude-vcs . | xz -1 -T3 > $backup"
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

    run_show "rm $backup && rm -r `dirname $backup`"
    export BAK_RESTORE=""
}
