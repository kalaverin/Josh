if [ `which curl` ]; then
    export READ_URI="`which curl` -fsSL"
elif [ `which wget` ]; then
    export READ_URI="`which wget` -qO -"
elif [ `which fetch` ]; then
    export READ_URI="`which fetch` -qo -"
else
    echo ' - please, install curl or wget :-\'
fi
