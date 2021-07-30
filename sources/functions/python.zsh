pir() {
    cat $1 | xargs -n 1 pip install
}

vact() {
    source $1/bin/activate
}

function dact {
    if [ "$VIRTUAL_ENV" != "" ]; then
        local cwd=`pwd`
        cd $VIRTUAL_ENV/bin && source activate && deactivate && cd $cwd
    fi
}

function get_venv_path {
    local cwd="`pwd`"
    unset JOSH_SELECT_VENV_PATH
    if [ "$1" != "" ]; then
        if [ -f "/tmp/env/$1/bin/activate" ]; then
            local env_path="/tmp/env/$1"
        else
            wd env
            if [ -f "$1/bin/activate" ]; then
                local env_path="`pwd`/$1"
                cd $cwd
            else
                echo " * venv >>$1<< isn't found"
                cd $cwd
                return 1
            fi
        fi
    else
        if [ "$VIRTUAL_ENV" = "" ]; then
            echo " * venv isn't activated"
            return 1
        fi
        local env_path="$VIRTUAL_ENV"
    fi
    local env_name=`basename "$env_path"`
    export JOSH_SELECT_VENV_PATH="$env_path"
}

function ten {
    local lwd="`pwd`"
    if [[ $1 =~ ^[0-9]\.[0-9]$ ]]; then
        local version="$1"
        local packages="${@:2}"
    else
        local version="2.7"
        local packages="$*"
    fi

    local pbin="/usr/bin/python$version"
    if [ ! -f "$pbin" ]; then
        echo " - not exists: >>$pbin<<" 1>&2
        return 1
    fi

    if [ ! -d "/tmp/env" ]; then
        mkdir /tmp/env
    fi
    cd /tmp/env

    if [ "$name" = "" ]; then
        local name="$(mktemp -d XXXX)"
    fi
    run_show "dact; virtualenv --python=$pbin $name && source $name/bin/activate && cd $lwd && pip install -U 'pip<=21.1' && pip install pipdeptree $packages"
}

function cdv {
    get_venv_path $*
    if [ "$JOSH_SELECT_VENV_PATH" != "" ]; then
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
    if [ -d "$env_site/site-packages" ]; then
        cd "$env_site/site-packages"
        if [ "${@:2}" != "" ]; then
            cd "${@:2}"
        fi
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
    dact && source bin/activate
    cd $cwd
}

function ten- {
    local cwd="`pwd`"
    cdv $*
    if [ $? -gt 0 ]; then
        return 1
    fi

    local vwd="`pwd`"
    if [[ ! $vwd =~ "^/tmp/env" ]]; then
        echo " * can't remove >>$vwd<< because isn't temporary"
        cd $cwd
        return 1
    fi

    if [ "$VIRTUAL_ENV" = "$vwd" ]; then
        run_show "cd $VIRTUAL_ENV/bin && source activate && deactivate && cd .."
    fi
    run_show "rm -rf $vwd; cd $cwd || cd ~"
}
