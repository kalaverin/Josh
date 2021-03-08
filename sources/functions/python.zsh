pir() {
    cat $1 | xargs -n 1 pip install
}

vact() {
    source $1/bin/activate
}

function dact {
    if [ "$VIRTUAL_ENV" != "" ]
    then
        local cwd=`pwd`
        local cmd="cd $VIRTUAL_ENV/bin && source activate && deactivate && cd $cwd"
        eval ${cmd}
    fi
}

function ven {
    local name="${1:-main}"
    local last_path="`pwd`"
    wd env
    vact $name
    cd $last_path
}

function tenv {
    local vers="2.7"

    if [ "$1" != "" ]
    then
        if [[ $1 =~ ^[0-9]\.[0-9]$ ]]
        then
            local vers="$1"
        else
            local name="$1"
        fi
    fi

    if [ "$2" != "" ]
    then
        if [[ $2 =~ ^[0-9]\.[0-9]$ ]]
        then
            local vers="$2"
        else
            local name="$2"
        fi
    fi

    if [ -f "/tmp/env/$name/bin/activate" ]
    then
        source /tmp/env/$name/bin/activate
    else
        local pbin="/usr/bin/python$vers"
        if [ ! -f "$pbin" ]
        then
            echo " - not exists: $pbin" 1>&2
            return 1
        fi

        if [ ! -d "/tmp/env" ]
        then
            mkdir /tmp/env
        fi
        local lwd="`pwd`"
        cd /tmp/env

        if [ "$name" = "" ]
        then
            local name="$(mktemp -d XXXX)"
        fi

        # echo " Go: $vers to $name" 1>&2
        virtualenv --python=$pbin $name
        source $name/bin/activate
        cd $lwd
    fi
}
