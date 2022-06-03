#!/bin/zsh

REQ_BINS=(
    cc
    git
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
        printf " ** fail ($0): missing required packages: $missing\n" >&2
        return 1
    fi
}


function compat.libraries {
    local missing=""
    for lib in $@; do
        pkg-config --libs --cflags "$lib" 1&>/dev/null 2&>/dev/null
        if [ "$?" -gt 0 ]; then
            if [ "$lib" = "openssl" ]; then

                if [ "$JOSH_OS" = "MAC" ]; then
                    local lookup_path="/usr/local/opt/"

                elif [ "$JOSH_OS" = "LINUX" ]; then
                    local lookup_path="/usr/lib/"

                elif [ "$JOSH_OS" = "BSD" ]; then
                    local lookup_path="/usr/local/"

                else
                    local missing="$missing $lib"
                    continue
                fi
                printf " ++ warn ($0): pkg-config $lib failed, we try to which openssl.pc in $lookup_path\n" >&2

                local openssl_path="$(fs_dirname `find "$lookup_path" -type f -name "openssl.pc" -follow 2>/dev/null | head -n 1`)"
                if [ ! -d "$openssl_path" ]; then
                    printf " ++ warn ($0): pkg-config $lib: nothing about openssl.pc in $lookup_path\n" >&2
                    local missing="$missing $lib"
                    continue
                fi
                printf " ++ warn ($0): retry pkg-config $lib: openssl.pc found in $openssl_path\n" >&2

                export PKG_CONFIG_PATH="$openssl_path"
                pkg-config --libs --cflags "$lib" 1>/dev/null 2>/dev/null
                if [ "$?" -gt 0 ]; then
                    printf " ++ warn ($0): pkg-config $lib: nothing about openssl.pc in $PKG_CONFIG_PATH\n" >&2
                    local missing="$missing $lib"
                    continue
                fi
                printf " ++ warn ($0): pkg-config $lib: all ok, continue\n" >&2

            else
                local missing="$missing $lib"
            fi
        fi
    done

    if [ -n "$missing" ]; then
        printf " ** fail ($0): missing required libraries: $missing\n" >&2
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
    if [ -n "$(uname | grep -i freebsd)" ]; then
        printf " -- info ($0): os freebsd $(uname -srv)\n" >&2
        export JOSH_OS="BSD"

        local cmd="sudo pkg install -y"
        local pkg="bash coreutils findutils git gnugrep gnuls gsed gtar openssl pkgconf python310 zsh"
        REQ_SYS_BINS=(
            bash
            pkg
            /usr/local/bin/gcut
            /usr/local/bin/gfind
            /usr/local/bin/gnuls
            /usr/local/bin/greadlink
            /usr/local/bin/grealpath
            /usr/local/bin/grep
            /usr/local/bin/gsed
            /usr/local/bin/gtar
        )

    elif [ -n "$(uname | grep -i darwin)" ]; then
        printf " -- info ($0): os macos $(uname -srv)\n" >&2
        export JOSH_OS="MAC"

        if [ ! -x "$(builtin which -p brew 2>/dev/null)" ]; then
            printf " -- info ($0): brew for MacOS strictly required, just run: curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | zsh\n" >&2
        fi

        local cmd="brew update && brew install"
        local pkg="bash coreutils findutils git gnu-tar grep gsed openssl pkg-config python@3 zsh"
        REQ_SYS_BINS=(
            bash
            brew
            /usr/local/bin/gcut
            /usr/local/bin/gfind
            /usr/local/bin/ggrep
            /usr/local/bin/gls
            /usr/local/bin/greadlink
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
            /usr/local/bin/gtar
        )


    elif [ -n "$(uname -srv | grep -i linux)" ]; then
        export JOSH_OS="LINUX"
        REQ_SYS_LIBS=(
            python
        )

        if [ -f "/etc/debian_version" ] || [ -n "$(uname -v | grep -Pi '(debian|ubuntu)')" ]; then
            REQ_SYS_BINS=( apt )
            printf " -- info ($0): os debian-based $(uname -srv)\n" >&2
            [ -x "$(builtin which -p apt 2>/dev/null)" ] && local bin="apt" || local bin="apt-get"

            local cmd="(sudo $bin update --yes --quiet || true) && sudo $bin install --yes --quiet --no-remove"
            local pkg="build-essential clang git libevent-dev libpq-dev libssl-dev make pkg-config python-dev python3 python3-distutils zsh"


        elif [ -f "/etc/arch-release" ] || [ -n "$(uname -v | grep -Pi '(arch|manjaro)')" ]; then
            REQ_SYS_BINS=( pacman )
            printf " -- info ($0): os arch: $(uname -srv)\n" >&2

            local cmd="sudo pacman --sync --noconfirm"
            local pkg="base-devel clang gcc git libevent openssl pkg-config postgresql-libs python3 tmux zsh"

        elif [ -n "$(uname -srv | grep -i gentoo)" ]; then
            printf " -- info ($0): os gentoo: $(uname -srv)\n" >&2

        elif [ -n "$(uname -srv | grep -i microsoft)" ]; then
            printf " -- info ($0): os unknown WSL: $(uname -srv)\n" >&2

        else
            printf " -- info ($0): os unknown linux: $(uname -srv)\n" >&2
        fi
    else
        printf " -- info ($0): os unknown: $(uname -srv)\n" >&2
        export JOSH_OS="UNKNOWN"
    fi

    compat.libraries $REQ_LIBS $REQ_SYS_LIBS && \
    compat.executables $REQ_BINS $REQ_SYS_BINS

    if [ "$?" -gt 0 ]; then
        local msg="please, install required packages and try again"
        [ "$cmd" ] && local msg="$msg: $cmd $pkg"

        if [ ! "$JOSH_SKIP_REQUIREMENTS_CHECK" ]; then
            printf " ++ warn ($0): $msg\n" >&2 && return 1
        else
            printf " ++ warn ($0): $msg\n" >&2
        fi
    else
        printf " -- info ($0): all requirements resolved, executives: $REQ_BINS $REQ_SYS_BINS, libraries: $REQ_LIBS $REQ_SYS_LIBS\n" >&2
    fi
    return 0
}
