#!/bin/sh

REQUIRED_BINARIES=(
    git
    jq
    pv
    python3
    tree
    zsh
)

function check_executables() {
    local missing=""
    for exe in $@; do
        if [ ! -f "`which $exe`" ]; then
            local missing="$missing $exe"
        fi
    done
    if [ "$missing" ]; then
        echo " + missing requirements:$missing"
        return 1
    fi
    return 0
}

function check_compliance() {
    if [ -n "$(uname | grep -i freebsd)" ]; then
        echo " + os: freebsd `uname -srv`"
        local cmd="sudo pkg install -y"
        local pkg="zsh git jq pv python3 coreutils gnugrep gnuls gsed"
        REQURED_SYSTEM_BINARIES=(
            /usr/local/bin/grep
            /usr/local/bin/gnuls
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
        )

    elif [ -n "$(uname | grep -i darwin)" ]; then
        echo " + os: macos `uname -srv`"
        local cmd="brew update && brew install"
        local pkg="zsh git jq pv python@3 grep gsed"
        REQURED_SYSTEM_BINARIES=(
            /usr/local/bin/grep
            /usr/local/bin/gnuls
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
        )

    elif [ -n "$(uname | grep -i linux)" ]; then
        if [ -n "$(uname -v | grep -Pi '(debian|ubuntu)')" ]; then
            echo " + os: debian-based `uname -srv`"
            local cmd="sudo apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove"
            local pkg="zsh git jq pv python3 tree"
        fi

    else
        echo ' - unknown os: `uname -srv`'
    fi

    check_executables $REQUIRED_BINARIES $REQURED_SYSTEM_BINARIES
    if [ $? -gt 0 ]; then
        echo " - please, install all packages and try again, may be just run: $cmd $pkg"
        return 0
    fi
    echo " + all requirements exists: $REQUIRED_BINARIES $REQURED_SYSTEM_BINARIES"
    return 1
}
