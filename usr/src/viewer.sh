if [ -d "$1" ]; then
    exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first $1

elif [ -f "$1" ]; then
    if [ -f "$JOSH_VIU" ] && [[ "$1" =~ "\.(jpg|png|gif)$" ]]; then
        viu --static --transparent $1

    elif [ -f "$JOSH_BAT" ]; then
        bat --color always --tabs 4 --paging never $1 --terminal-width $FZF_PREVIEW_COLUMNS --decorations auto

    else
        less $1
    fi
fi
