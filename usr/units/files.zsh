function __stream_pak {
    if [ -z "$*" ]; then
        fail $0 "args doesn't exist" >&2
        return 1
    fi

    local result="tar -cO $1 --numeric-owner --sparse ."
    if [ "$ASH_OS" = 'BSD' ]; then
        local result="$result -f -"
    fi
    echo "$result"
}


function __stream_unpak {
    local result='tar -x --numeric-owner --preserve-permissions'
    if [ "$ASH_OS" = 'BSD' ]; then
        local result="$result -f -"
    fi
    echo "$result"
}


function __setup.cfg.backup_file_get {
    local backup="$BAK_RESTORE"
    if [ "$backup" = "" ]; then
        fail $0 "BAK_RESTORE isn't set" >&2
        return 1

    elif [ -z "$ASH_PAQ" ] || [ -z "$ASH_QAP" ]; then
        fail $0 "zstd, xz, lz4 and gzip doesn't exists" >&2
        return 2
    fi
    echo "$backup"
}


function bak {
    local source timemark target backup

    if [ -f "$BAK_RESTORE" ]; then
        warn $0 "already found: $BAK_RESTORE"

    elif [ -z "$ASH_PAQ" ] || [ -z "$ASH_QAP" ]; then
        fail $0 "zstd, xz, lz4 and gzip doesn't exists" >&2
        return 127
    fi

    local root="$(git.this.root)"
    [ -z "$root" ] && local root="$PWD"

    source="$(fs.basename "$root")" || return "$?"
    timemark="$(date "+%Y.%m.%d-%H.%M.%S")" || return "$?"
    target="$(temp.dir)/bak/$source" || return "$?"
    backup="$target/$source-$timemark-$(get.name).tar" || return "$?"

    git.mtime.set 2>&1 >/dev/null

    run.show "mkdir -p \"$target\" 2>/dev/null; $(__stream_pak --exclude-vcs) | $ASH_PAQ > $backup"
    info $0 "cat $backup | $ASH_QAP | $(__stream_unpak)"
    export BAK_RESTORE="$backup"
}


function bakf {
    local source timemark target backup

    if [ -f "$BAK_RESTORE" ]; then
        warn $0 "already found: $BAK_RESTORE"

    elif [ -z "$ASH_PAQ" ] || [ -z "$ASH_QAP" ]; then
        fail $0 " - fatal: zstd, xz, lz4 and gzip doesn't exists" >&2
        return 127
    fi

    local root="$(git.this.root)"
    [ -z "$root" ] && local root="$PWD"

    source="$(fs.basename "$root")" || return "$?"
    timemark="$(date "+%Y.%m.%d-%H.%M.%S")" || return "$?"
    target="$(temp.dir)/bak/$source" || return "$?"
    backup="$target/$source-$timemark-$(get.name).tar" || return "$?"

    git.mtime.set 2>&1 >/dev/null

    run.show "mkdir -p \"$target\" 2>/dev/null; $(__stream_pak --exclude-vcs-ignores) | $ASH_PAQ > $backup"
    info $0 "cat $backup | $ASH_QAP | $(__stream_unpak)"
    export BAK_RESTORE="$backup"
}


function kab {
    local backup="$(__setup.cfg.backup_file_get 2>/dev/null)"
    [ -z "$backup" ] && return "$?"

    git.is_clean || return "$?"

    run.show "cat $backup | $ASH_QAP | $(__stream_unpak)" && return 0
    return "$?"
}

function kabf {
    local backup="$(__setup.cfg.backup_file_get 2>/dev/null)"
    [ -z "$backup" ] && return "$?"

    run.show "cat $backup | $ASH_QAP | $(__stream_unpak)" && return 0
    return "$?"
}

function bakrm {
    local backup="$(__setup.cfg.backup_file_get 2>/dev/null)"
    [ -z "$backup" ] && return "$?"

    if [ -x "$(which rip)" ]; then
        local exe="$(which rip)"
        local cmd="$exe $backup"
    else
        local cmd="rm $backup"
    fi

    run.show "$cmd"
    unset BAK_RESTORE
}
