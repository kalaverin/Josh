#!/bin/sh

if [ -n "$(uname | grep -i freebsd)" ]; then
    "pkg install -y zsh git jq pv py38-httpie coreutils gnugrep gnuls gsed"

elif [ -n "$(uname | grep -i darwin)" ]; then
    "brew update && brew install zsh git jq pv httpie grep gsed"

elif [ -n "$(uname | grep -i linux)" ]; then
    if [ -n "$(uname -v | grep -i debian)" ]; then
        "apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git httpie jq pv"

    elif [ -n "$(uname -v | grep -i ubuntu)" ]; then
        "apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git httpie jq pv"
    fi
fi
