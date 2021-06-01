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
        cd $VIRTUAL_ENV/bin && source activate && deactivate && cd $cwd
    fi
}

function get_venv_path {
    local cwd="`pwd`"
    unset JOSH_SELECT_VENV_PATH
    if [ "$1" != "" ]
    then
        if [ -f "/tmp/env/$1/bin/activate" ]
        then
            local env_path="/tmp/env/$1"
        else
            wd env
            if [ -f "$1/bin/activate" ]
            then
                local env_path="`pwd`/$1"
                cd $cwd
            else
                echo " * venv $1 isn't found"
                cd $cwd
                return 1
            fi
        fi
    else
        if [ "$VIRTUAL_ENV" = "" ]
        then
            echo " * venv isn't activated"
            return 1
        fi
        local env_path="$VIRTUAL_ENV"
    fi
    local env_name=`basename "$env_path"`
    export JOSH_SELECT_VENV_PATH="$env_path"
}

function ten {
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
        run_silent "dact && source /tmp/env/$name/bin/activate"
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
        run_show "dact && virtualenv --python=$pbin $name && source $name/bin/activate && pip install -U 'pip<=21.1' && pip install pipdeptree && cd $lwd"
    fi
}

function cdv {
    get_venv_path $*
    if [ "$JOSH_SELECT_VENV_PATH" != "" ]
    then
        cd $JOSH_SELECT_VENV_PATH
        unset JOSH_SELECT_VENV_PATH
    else
        return 1
    fi
}

function cds {
    local cwd="`pwd`"

    cdv $*
    if [ $? -gt 0 ]; then
        return 1
    fi

    local env_site=`find lib/ -maxdepth 1 -type d -name 'python*'`
    if [ -d "$env_site/site-packages" ]
    then
        cd "$env_site/site-packages"
    else
        echo " * something wrong for >>$env_path<<, path: >>$env_site><"
        cd $cwd
    fi
}

function ven {
    local cwd="`pwd`"
    cdv $*
    if [ $? -gt 0 ]; then
        return 1
    fi
    dact && source bin/activate && cd $cwd
}
