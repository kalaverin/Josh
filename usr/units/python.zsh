. $JOSH/lib/shared.sh

# ———

local THIS_DIR=`dirname "$(readlink -f "$0")"`
local INCLUDE_DIR="`realpath $THIS_DIR/pip`"

local PIP_LIST_ALL="$INCLUDE_DIR/pip_list_all.sh"
local PIP_LIST_TOP="$INCLUDE_DIR/pip_list_top_level.sh"
local PIP_PKG_INFO="$INCLUDE_DIR/pip_pkg_info.sh"

# ———

pir() {
    cat $1 | xargs -n 1 pip install
}

vact() {
    local cwd="`pwd`"
    local venv="`realpath ${VIRTUAL_ENV:-$1}`"
    [ ! -d "$venv" ] && return 1
    dact; cd "$venv" && source bin/activate; cd $cwd
}

function dact {
    if [ "$VIRTUAL_ENV" != "" ]; then
        local cwd="`pwd`"
        cd $VIRTUAL_ENV/bin && source activate && deactivate
        cd $cwd
    fi
}

function get_venv_path {
    local cwd="`pwd`"
    unset JOSH_SELECT_VENV_PATH
    if [ "$1" ]; then
        local temp="`get_tempdir`"
        if [ -f "$temp/env/$1/bin/activate" ]; then
            local env_path="$temp/env/$1"
        else
            wd env
            if [ -f "$1/bin/activate" ]; then
                local env_path="`pwd`/$1"
                cd $cwd
            else
                echo " * venv \`$1\` isn't found"
                cd $cwd
                return 1
            fi
        fi
    else
        if [ "$VIRTUAL_ENV" = "" ]; then
            echo " - venv isn't activated"
            return 1
        fi
        local env_path="$VIRTUAL_ENV"
    fi
    local env_name=`basename "$env_path"`
    export JOSH_SELECT_VENV_PATH="$env_path"
}

function ten {
    local cwd="`pwd`"
    local packages="$*"

    if [[ "$1" =~ ^[0-9]\.[0-9]$ ]]; then
        local exe="`which -p python$1`"
        local packages="${@:2}"

    elif [ "$1" = "3" ]; then
        if [ ! -f "$PYTHON3" ]; then
            . $JOSH/lib/python.sh && python_init
            if [ $? -gt 0 ]; then
                echo " - when detect last python3 something wrong, stop"
            fi
        fi
        if [ ! -f "$PYTHON3" ]; then
            echo " - default \$PYTHON3=\`$PYTHON3\` python isn't accessible" 1>&2
            return 1
        fi
        local exe="$PYTHON3"
        local packages="${@:2}"

    elif [[ "$1" =~ ^[0-9] ]]; then
        echo " - couldn't autodetect python for version \`$1\`" 1>&2
        return 2

    else
        local exe="`which -p python2.7`"
    fi

    dact
    if [ ! -f "$exe" ]; then
        echo " - couldn't search selected python \`$exe\`" 1>&2
        return 1
    fi

    if [ ! -f "`which -p virtualenv`" ]; then
        . $JOSH/lib/python.sh && pip_init
        if [ $? -gt 0 ]; then
            echo " - when init virtualenv something wrong, stop"
        fi
    fi

    local name="$(dirname `mktemp -duq`)/env/`petname -s . -w 3 -a`"
    mkdir -p "$name" && \
        cd "`realpath $name/../`" && \
        rm -rf "$name" && \
    virtualenv --python=$exe "$name" && \
        source $name/bin/activate && cd $cwd && \
        $SHELL -c "pip install pip-chill pipdeptree $packages"
}

function cdv {
    get_venv_path $*
    if [ "$JOSH_SELECT_VENV_PATH" != "" ]; then
        cd $JOSH_SELECT_VENV_PATH
        unset JOSH_SELECT_VENV_PATH
        return 0
    fi
    return 1
}

function cds {
    local cwd="`pwd`"
    cdv $* || ([ $? -gt 0 ] && return 1)

    local env_site=`find lib/ -maxdepth 1 -type d -name 'python*'`
    if [ -d "$env_site/site-packages" ]; then
        cd "$env_site/site-packages"
        [ "${@:2}" ] && cd ${@:2}
    else
        echo " * something wrong for >>$env_path<<, path: >>$env_site><"
        cd $cwd
    fi
}

function ven {
    local cwd="`pwd`"
    cdv $* || ([ $? -gt 0 ] && return 1)

    dact && source bin/activate && cd $cwd
}

function ten- {
    local cwd="`pwd`"
    cdv $* || ([ $? -gt 0 ] && return 1)

    local vwd="`pwd`"
    local temp="`get_tempdir`"
    if [[ ! $vwd =~ "^$temp/env" ]]; then
        echo " * can't remove >>$vwd<< because isn't temporary"
        cd $cwd
        return 1
    fi

    if [ "$VIRTUAL_ENV" = "$vwd" ]; then
        run_show "cd $VIRTUAL_ENV/bin && source activate && deactivate && cd .."
    fi
    run_show "rm -rf $vwd 2>/dev/null; cd $cwd || cd ~"
}

# ———

visual_freeze() {
    . $JOSH/lib/python.sh
    pip_init || return 1

    local venv="`basename ${VIRTUAL_ENV:-''}`"
    local preview="echo {2} | xargs -n 1 $SHELL $PIP_PKG_INFO"
    local value="$(sh -c "
        $SHELL $PIP_LIST_TOP \
        | $FZF \
            --multi \
            --nth=2 \
            --tiebreak='index' \
            --layout=reverse-list \
            --preview='$preview' \
            --prompt='packages $venv > ' \
            --preview-window="left:`get_preview_width`:noborder" \
            --bind='ctrl-s:reload($SHELL $PIP_LIST_ALL),ctrl-d:reload($SHELL $PIP_LIST_TOP)' \
        | tabulate -i 2 | $UNIQUE_SORT | $LINES_TO_LINE
    ")"

    if [ "$value" != "" ]; then
        if [ "$BUFFER" != "" ]; then
            local command="$BUFFER "
        else
            local command=""
        fi
        LBUFFER="$command$value"
        RBUFFER=''
    fi

    zle reset-prompt
    return 0
}
zle -N visual_freeze

# ———

if [ -d "$VIRTUAL_ENV" ]; then
    vact $VIRTUAL_ENV
fi
