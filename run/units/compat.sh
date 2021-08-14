#!/bin/sh

REQUIRED_BINARIES=(
    git
    jq
    pkg-config
    pv
    python3
    tree
    zsh
)
REQUIRED_LIBRARIES=(
    openssl
)

function check_executables() {
    local missing=""
    for exe in $@; do
        if [ ! -f "`which $exe`" ]; then
            local missing="$missing $exe"
        fi
    done
    if [ "$missing" ]; then
        echo " + missing required packages:$missing"
        return 1
    fi
    return 0
}


function check_libraries() {
    local missing=""
    for lib in $@; do
        $SHELL -c "pkg-config --libs --cflags $lib" 1&>/dev/null 2&>/dev/null
        if [ "$?" -gt 0 ]; then
            local missing="$missing $lib"
        fi
    done
    if [ "$missing" ]; then
        echo " + missing required libraries:$missing"
        return 1
    fi
    return 0
}


version_not_compatible()
{
    if [ "$1" != "$2" ]; then
        local choice=$(sh -c "printf '%s\n%s\n' "$1" "$2" | sort --version-sort | tail -n 1")
        [ $(sh -c "printf '%s' "$choice" | grep -Pv '^($2)$'") ] && return 0
    fi
    return 1
}


function check_compliance() {
    if [ -n "$(uname | grep -i freebsd)" ]; then
        echo " + os: freebsd `uname -srv`"
        local cmd="sudo pkg install -y"
        local pkg="zsh git coreutils gnugrep gnuls gsed jq openssl pkgconf pv python39"
        REQURED_SYSTEM_BINARIES=(
            pkg
            /usr/local/bin/grep
            /usr/local/bin/gnuls
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
        )

    elif [ -n "$(uname | grep -i darwin)" ]; then
        echo " + os: macos `uname -srv`"
        local cmd="brew update && brew install"
        local pkg="zsh git coreutils grep gsed jq openssl pkg-config pv python@3 tree"
        REQURED_SYSTEM_BINARIES=(
            brew
            /usr/local/bin/ggrep
            /usr/local/bin/gls
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
        )

    elif [ -n "$(uname -v | grep -Pi '(debian|ubuntu)')" ]; then
        echo " + os: debian-based `uname -srv`"
        local cmd="sudo apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove"
        local pkg="zsh git jq pv python3 python3-distutils tree libssl-dev"
        REQURED_SYSTEM_BINARIES=(
            apt
        )

    elif [ -n "$(uname -srv | grep -i gentoo)" ]; then
        echo " + os: gentoo: `uname -srv`"

    elif [ -n "$(uname | grep -i linux)" ]; then
        echo " - unknown linux: `uname -srv`"

    else
        echo " - unknown os: `uname -srv`"
    fi

    check_executables $REQUIRED_BINARIES $REQURED_SYSTEM_BINARIES && \
        check_libraries $REQUIRED_LIBRARIES

    if [ $? -gt 0 ]; then
        local msg=" - please, install required packages and try again"
        [ "$cmd" ] && local msg="$msg: $cmd $pkg"
        echo "$msg" && return 0
    fi

    echo " + all requirements exists: $REQUIRED_BINARIES $REQURED_SYSTEM_BINARIES"
    return 1
}
