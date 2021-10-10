if [ ! -e "$1" ]; then
    echo "Not found \`$1\`"

elif [ -d "$1" ]; then
    if [ -x "`which lsd`" ]; then
        lsd --almost-all --dereference --extensionsort --classify --long --oneline --versionsort --color always --blocks permission,user,group,date,size,name --date +"%Y-%m-%d %H:%M:%S" --group-dirs first --icon never --ignore-glob "*.pyc" "$1"
    else
        ls -la "$1"
    fi

elif [ -f "$1" ]; then
    if [ -x "`which viu`" ] && [[ "$1" =~ "\.(jpg|png|gif)$" ]]; then
        viu --static --transparent "$1"

    elif [ -x "`which bat`" ]; then
        bat --color always --tabs 4 --paging never "$1" --terminal-width $FZF_PREVIEW_COLUMNS --decorations auto

    else
        less "$1"
    fi
fi
