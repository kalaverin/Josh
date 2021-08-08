#!/bin/bash

IFS=':' read -r -a INPUT <<< "$1"
file=${INPUT[0]}
line=${INPUT[1]}

if hash bat 2>/dev/null
then
    if ! [ -z $line ]
    then
        topline=$(($line - 5))
        if [ $topline -lt 1 ]
        then
            topline=1
        fi
        bat --style=numbers --color=always --theme=silence --line-range $topline: --highlight-line $line "$file"
    else
        bat --style=numbers --color=always --theme=silence "$file"
    fi
else
    cat "$file"
fi
