#!/bin/zsh


[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    REQ_BINS=(
        cc
        cmake
        jq
        git
        go
        make
        pkg-config
        python3
        rsync
        tmux
        zsh
    )

    REQ_LIBS=(
        openssl
        libevent
    )


    function compat.executables {
        local missing=""
        for bin in $@; do
            if [ ! -x "$(builtin which -p "$bin" 2>/dev/null)" ]; then
                local missing="$missing $bin"
            fi
        done
        if [ -n "$missing" ]; then
            fail $0 "missing required packages: $missing"
            return 1
        fi
    }


    function compat.libraries {
        local missing=""
        for lib in $@; do
            pkg-config --libs --cflags "$lib" 1&>/dev/null 2&>/dev/null
            if [ "$?" -gt 0 ]; then
                if [ "$lib" = "openssl" ]; then

                    if [ "$ASH_OS" = "MAC" ]; then
                        local lookup_path="/usr/local/opt/"

                    elif [ "$ASH_OS" = "LINUX" ]; then
                        local lookup_path="/usr/lib/"

                    elif [ "$ASH_OS" = "BSD" ]; then
                        local lookup_path="/usr/local/"

                    else
                        local missing="$missing $lib"
                        continue
                    fi
                    warn $0 "pkg-config $lib failed, we try to which openssl.pc in $lookup_path"

                    local openssl_path="$(fs.dirname `find "$lookup_path" -type f -name "openssl.pc" -follow 2>/dev/null | head -n 1`)"
                    if [ ! -d "$openssl_path" ]; then
                        warn $0 "pkg-config $lib: nothing about openssl.pc in $lookup_path"
                        local missing="$missing $lib"
                        continue
                    fi
                    warn $0 "retry pkg-config $lib: openssl.pc found in $openssl_path"

                    export PKG_CONFIG_PATH="$openssl_path"
                    pkg-config --libs --cflags "$lib" 1>/dev/null 2>/dev/null
                    if [ "$?" -gt 0 ]; then
                        warn $0 "pkg-config $lib: nothing about openssl.pc in $PKG_CONFIG_PATH"
                        local missing="$missing $lib"
                        continue
                    fi
                    warn $0 "pkg-config $lib: all ok, continue"

                else
                    local missing="$missing $lib"
                fi
            fi
        done

        if [ -n "$missing" ]; then
            fail $0 "missing required libraries: $missing"
            return 1
        fi
        return 0
    }


    function version_not_compatible {
        if [ "$1" != "$2" ]; then
            local choice=$($SHELL -c "printf '%s\n%s\n' "$1" "$2" | sort --version-sort | tail -n 1")
            [ $($SHELL -c "printf '%s' "$choice" | grep -Pv '^($2)$'") ] && return 0
        fi
        return 1
    }


    function compat.compliance {
        local osname="$(uname -srv)"
        if [ -n "$(echo "$osname" | grep -i freebsd)" ]; then
            info $0 "os freebsd: $osname"
            export ASH_OS="BSD"

            local cmd="sudo pkg install -y"
            local pkg="bash coreutils findutils jq git gnugrep gnuls golang gsed gtar libevent openssl pkgconf python310 rsync sudo tmux zsh"
            REQ_SYS_BINS=(
                bash
                pkg
                sudo
                /usr/local/bin/direnv
                /usr/local/bin/gcut
                /usr/local/bin/gfind
                /usr/local/bin/gnuls
                /usr/local/bin/greadlink
                /usr/local/bin/grealpath
                /usr/local/bin/grep
                /usr/local/bin/gsed
                /usr/local/bin/gtar
            )

        elif [ -n "$(echo "$osname" | grep -i darwin)" ]; then
            info $0 "os macos: $osname"
            export ASH_OS="MAC"

            if [ ! -x "$(builtin which -p brew 2>/dev/null)" ]; then
                info $0 "brew for MacOS strictly required, just run: curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | zsh"
            fi

            local cmd="brew update && brew install"
            local pkg="bash coreutils findutils jq git gnu-tar golang grep gsed openssl pkg-config python@3 zsh"
            REQ_SYS_BINS=(
                bash
                brew
                gcut
                gfind
                ggrep
                gls
                greadlink
                grealpath
                gsed
                gtar
            )


        elif [ -n "$(echo "$osname" | grep -i linux)" ]; then
            export ASH_OS="LINUX"
            REQ_SYS_LIBS=(
                # python
            )

            if [ -f "/etc/debian_version" ] || [ -n "$(uname -v | grep -Pi '(debian|ubuntu)')" ]; then
                REQ_SYS_BINS=( apt )
                info $0 "os debian-based: $osname"
                [ -x "$(builtin which -p apt 2>/dev/null)" ] && local bin="apt" || local bin="apt-get"

                local cmd="(sudo $bin update --yes --quiet || true) && sudo $bin install --yes --quiet --no-remove"
                local pkg="build-essential clang jq git libevent-dev libpq-dev libssl-dev make tmux pkg-config python3 python3-distutils zsh"


            elif [ -f "/etc/arch-release" ] || [ -n "$(uname -v | grep -Pi '(arch|manjaro)')" ]; then
                REQ_SYS_BINS=( pacman )
                info $0 "os arch: $osname"

                local cmd="sudo pacman --sync --noconfirm"
                local pkg="base-devel clang cmake gcc git golang libevent openssl pkg-config postgresql-libs python3 tmux zsh"

            elif [ -n "$(echo "$osname" | grep -i gentoo)" ]; then
                info $0 "os gentoo: $osname"

            elif [ -n "$(echo "$osname" | grep -i microsoft)" ]; then
                info $0 "os unknown WSL: $osname"

            else
                info $0 "os unknown linux: $osname"
            fi
        else
            info $0 "os unknown: $osname"
            export ASH_OS="UNKNOWN"
        fi

        # TODO:
        # local binaries=( xargs realpath awk grep test2 )
        # if local missing="$(fs.lookup.missing "$binaries")" && [ -n "$missing" ]; then
        #     fail $0 "missing binaries: $missing"
        #     return 1
        # fi

        compat.libraries $REQ_LIBS $REQ_SYS_LIBS && \
        compat.executables $REQ_BINS $REQ_SYS_BINS

        if [ "$?" -gt 0 ]; then
            local msg="please, install required packages and try again"
            [ "$cmd" ] && local msg="$msg: $cmd $pkg"

            warn $0 "$msg"
            if [ -z "$ASH_SKIP_REQUIREMENTS_CHECK" ]; then
                return 1
            fi
        else
            info $0 "all requirements resolved, executives: $REQ_BINS $REQ_SYS_BINS, libraries: $REQ_LIBS $REQ_SYS_LIBS"
        fi
        return 0
    }
fi
