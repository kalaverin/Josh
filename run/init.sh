[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")
    local osname="$(uname)"

    setopt no_case_match

    if [[ "$osname" -regex-match 'freebsd' ]]; then
        export ASH_OS="BSD"
        fs.link 'ls'    '/usr/local/bin/gnuls' >/dev/null
        fs.link 'grep'  '/usr/local/bin/grep'  >/dev/null

    elif [[ "$osname" -regex-match 'darwin' ]]; then
        export ASH_OS="MAC"
        fs.link 'ls'    '/usr/local/bin/gls'   >/dev/null
        fs.link 'grep'  '/usr/local/bin/ggrep' >/dev/null

        dirs=(
            bin
            sbin
            usr/bin
            usr/sbin
            usr/local/bin
            usr/local/sbin
        )

        for dir in $dirs; do
            if [ -d "/Library/Apple/$dir" ]; then
                export PATH="$PATH:/Library/Apple/$dir"
            fi
        done

    else
        if [[ "$osname" -regex-match 'linux' ]]; then
            export ASH_OS="LINUX"
        else
            fail $0 "unsupported OS '$(uname -srv)'"
            export ASH_OS="UNKNOWN"
        fi

        dirs=(
            bin
            sbin
            usr/bin
            usr/sbin
            usr/local/bin
            usr/local/sbin
        )

        for dir in $dirs; do
            if [ -d "/snap/$dir" ]; then
                export PATH="$PATH:/snap/$dir"
            fi
        done
    fi

    if [ "$ASH_OS" = 'BSD' ] || [ "$ASH_OS" = 'MAC' ]; then
        fs.link 'cut'       '/usr/local/bin/gcut'      >/dev/null
        fs.link 'find'      '/usr/local/bin/gfind'     >/dev/null
        fs.link 'head'      '/usr/local/bin/ghead'     >/dev/null
        fs.link 'readlink'  '/usr/local/bin/greadlink' >/dev/null
        fs.link 'realpath'  '/usr/local/bin/grealpath' >/dev/null
        fs.link 'sed'       '/usr/local/bin/gsed'      >/dev/null
        fs.link 'tail'      '/usr/local/bin/gtail'     >/dev/null
        fs.link 'tar'       '/usr/local/bin/gtar'      >/dev/null
        fs.link 'xargs'     '/usr/local/bin/gxargs'    >/dev/null
        export ASH_MD5_PIPE="$(which md5)"
    else
        export ASH_MD5_PIPE="$(which md5sum) | $(which cut) -c -32"
    fi

    source "$(fs.dirname $0)/hier.sh"
fi
