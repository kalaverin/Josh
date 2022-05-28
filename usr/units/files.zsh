source "$JOSH/lib/shared.sh"


function __stream_pak {
    if [ "$JOSH_OS" = 'BSD' ]; then
        echo 'tar -cO --exclude-vcs --numeric-owner --sparse . -f -'
    else
        echo 'tar -cO --exclude-vcs --numeric-owner --sparse .'
    fi
}


function __stream_unpak {
    if [ "$JOSH_OS" = 'BSD' ]; then
        echo 'tar -x --numeric-owner --preserve-permissions -f -'
    else
        echo 'tar -x --numeric-owner --preserve-permissions'
    fi
}


function backup_file_get {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        echo " - $0 fatal: BAK_RESTORE isn't set" 1>&2
        return 1

    elif [ -z "$JOSH_PAQ" ] || [ -z "$JOSH_QAP" ]; then
        echo " - $0 fatal: zstd, xz, lz4 and gzip doesn't exists" 1>&2
        return 2
    fi
    echo "$backup"
}


function bak {
    if [ -f "$BAK_RESTORE" ]; then
        echo " * backup already found: $BAK_RESTORE"

    elif [ -z "$JOSH_PAQ" ] || [ -z "$JOSH_QAP" ]; then
        echo " - fatal: zstd, xz, lz4 and gzip doesn't exists" 1>&2
        return 1
    fi

    local root="`git_root`"
    [ -z "$root" ] && local root="$PWD"

    local source="`fs_basename "$root"`"
    [ "$?" -gt 0 ] && return 1

    local timemark="`date "+%Y.%m.%d-%H.%M.%S"`"
    [ "$?" -gt 0 ] && return 2

    local target="`get_tempdir`/bak/$source"
    [ "$?" -gt 0 ] && return 3

    local backup="$target/$timemark-`make_human_name`.tar"
    [ "$?" -gt 0 ] && return 4

    run_show "mkdir -p \"$target\" 2>/dev/null; `__stream_pak` | $JOSH_PAQ > $backup"
    echo " => cat $backup | $JOSH_QAP | `__stream_unpak`"
    export BAK_RESTORE="$backup"
}


function bakf {
    if [ -f "$BAK_RESTORE" ]; then
        echo " * backup already found: $BAK_RESTORE"

    elif [ -z "$JOSH_PAQ" ] || [ -z "$JOSH_QAP" ]; then
        echo " - fatal: zstd, xz, lz4 and gzip doesn't exists" 1>&2
        return 1
    fi

    local root="`git_root`"
    [ -z "$root" ] && local root="$PWD"

    local source="`fs_basename "$root"`"
    [ "$?" -gt 0 ] && return 1

    local timemark="`date "+%Y.%m.%d-%H.%M.%S"`"
    [ "$?" -gt 0 ] && return 2

    local target="`get_tempdir`/bak/$source"
    [ "$?" -gt 0 ] && return 3

    local backup="$target/$timemark-`make_human_name`.tar"
    [ "$?" -gt 0 ] && return 4

    run_show "mkdir -p \"$target\" 2>/dev/null; tar `__stream_pak` | $JOSH_PAQ > $backup"
    echo " => cat $backup | $JOSH_QAP | `__stream_unpak`"
    export BAK_RESTORE="$backup"
}


function kab {
    local backup="`backup_file_get 2>/dev/null`"
    [ -z "$backup" ] && return "$?"

    git_repository_clean || return "$?"

    run_show "cat $backup | $JOSH_QAP | `__stream_unpak`" && return 0
    return "$?"
}

function kabf {
    local backup="`backup_file_get 2>/dev/null`"
    [ -z "$backup" ] && return "$?"

    run_show "cat $backup | $JOSH_QAP | `__stream_unpak`" && return 0
    return "$?"
}

function bakrm {
    local backup="`backup_file_get 2>/dev/null`"
    [ -z "$backup" ] && return "$?"

    if [ -x "`which rip`" ]; then
        local exe="`which rip`"
        local cmd="$exe $backup"
    else
        local cmd="rm $backup"
    fi

    run_show "$cmd"
    unset BAK_RESTORE
}
