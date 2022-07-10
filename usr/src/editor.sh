if [ -d "$1" ]; then
    builtin cd "$1"

elif [ -f "$1" ]; then

    if [ -f "$ASH_VIU" ] && [[ "$1" =~ "\.(jpe?g|png|gif|ico)$" ]]; then
        viu --static --transparent $1

    else
        $EDITOR $1

    fi
fi
