local THIS_DIR="$(fs.realdir "$0")"
local INCLUDE_DIR="$(fs.realpath $THIS_DIR/pip)"

local PIP_LIST_ALL="$INCLUDE_DIR/pip_list_all.sh"
local PIP_LIST_TOP="$INCLUDE_DIR/pip_list_top_level.sh"
local PIP_PKG_INFO="$INCLUDE_DIR/pip_pkg_info.sh"

# ———

function venv.on {
    local venv="$(venv.path $*)"
    if [ -n "$venv" ] && [ -d "$venv" ]; then
        venv.off >/dev/null; source "$venv/bin/activate"
        path.rehash
    fi
}

function venv.path.activate {
    local name="$(fs.realpath ${1:-$VIRTUAL_ENV})"

    if [ ! -d "$name" ]; then
        return 1

    elif [ "$VIRTUAL_ENV" = "$name" ]; then
        source "$name/bin/activate"

    elif [ "$VIRTUAL_ENV" ]; then
        venv.off >/dev/null; source "$name/bin/activate"

    else
        source "$name/bin/activate"
    fi
    path.rehash
}

function venv.temp.dir {
    if [ -z "$ASH_PY_TEMP_ENVS_ROOT" ]; then
        local directory="$(temp.dir)/$(fs.basename "$ASH_PY_ENVS_ROOT")"
        if [ ! -d "$directory" ]; then
            mkdir -p "$directory"
        fi
        export ASH_PY_TEMP_ENVS_ROOT="$directory"
    fi
    echo "$ASH_PY_TEMP_ENVS_ROOT"
}

function venv.node {
    ash.eval "lib/python.sh"
    pip.exe >/dev/null || return 1

    local venv="${VIRTUAL_ENV:-''}"
    if [ ! -d "$venv" ]; then
        fail $0 "venv must be activated"
        return 2
    fi
    local venvname=`fs.basename "$venv"`

    info $0 "using venv: $venvname ($venv)"
    venv.path.activate "$venv"

    local pip="$(which pip)"
    if [ ! -x "$pip" ]; then
        fail $0 "pip in venv '$VIRTUAL_ENV' isn't found"
        return 3
    fi
    info $0 "using pip: $pip"

    local pip="$pip --no-python-version-warning --disable-pip-version-check --no-input --quiet"
    if [ $($SHELL -c "$pip freeze | grep nodeenv | wc -l") -eq 0 ]; then
        run_show "$pip install nodeenv" && venv.path.activate "$venv"
    fi

    local nodeenv="$(which nodeenv)"
    if [ ! -x "$nodeenv" ]; then
        fail $0 "nodeenv in venv '$VIRTUAL_ENV' isn't found"
        return 4
    fi
    info $0 "using nodeenv: $nodeenv"

    if [[ "$1" =~ ^[0-9] ]]; then
        # TODO: need: 14.5 -> 14.5.0 and versionlist too
        local version="$1"
    else
        local version="$($SHELL -c "
            nodeenv --list 2>&1 | sd '\n' ' ' | sd '\s+' '\n' | sort -rV \
            | $FZF \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --tiebreak=index --jump-labels="$FZF_JUMPS" \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:abort' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --bind='alt-space:jump-accept' \
                --color="$FZF_THEME" \
                --reverse --min-height='11' --height='11' \
                --prompt='select node version for $venvname > ' \
                -i --select-1 --filepath-word
        ")"
    fi

    if [ -n "$version" ]; then
        info $0 "deploy node v$version"
        run_show "nodeenv --python-virtualenv --node=$version"
        path.rehash
    fi
}

function venv.path {
    if [ "$1" ]; then
        if [ -d "$1" ] && [ -f "$1/bin/activate" ]; then
            echo "$1"

        elif [ -f "$ASH_PY_ENVS_ROOT/$1/bin/activate" ]; then
            echo "$ASH_PY_ENVS_ROOT/$1"

        else
            local temp="$(venv.temp.dir)"
            if [ -f "$temp/$1/bin/activate" ]; then
                echo "$temp/$1"
            else
                fail $0 "venv '$1' isn't found"
            fi
        fi

    elif [ "$VIRTUAL_ENV" ]; then
        echo "$VIRTUAL_ENV"
    fi
}

function py.from.version {
    ash.eval "lib/python.sh" && py.home >/dev/null

    if [ "$?" -gt 0 ]; then
        fail $0 "python3 import something wrong, stop"
        return 1
    fi

    path.rehash
    if [[ "$1" =~ ^[0-9]\.[0-9]+$ ]]; then
        local python="$(which "python$1")"

    elif [ "$1" = "3" ]; then
        if [ -x "$commands[python]" ]; then
            local python="$commands[python]"
        else
            local python="$(which "python3")"
        fi
    elif [ -z "$1" ]; then
        local python="$(which "python2.7")"
    fi
    echo "$python"
}

function venv.make {
    local cwd="$CWD"

    if [ -z "$1" ]; then
        fail $0 "call without args, I need to do — what?"
        return 1

    elif [[ "$1" =~ ^[0-9a-z]+[0-9a-z\.-]*[0-9a-z]+$ ]]; then
        local name="$1"
        local full="$ASH_PY_ENVS_ROOT/$name"

    elif [[ "$1" =~ ^/.+/[0-9a-z]+[0-9a-z\.-]*[0-9a-z]+$ ]]; then
        local name="$(fs.basename "$1")"
        local full="$1"
    fi

    local root="$(fs.dirname "$full")"
    if [ ! -d "$root" ]; then
        mkdir -p "$root"

    elif [ -d "$full" ]; then
        fail $0 "full '$name' already exists in '$root'"
        return 1
    fi

    local python="`py.from.version $2`"
    if [ ! -x "$python" ]; then
        fail $0 "couldn't autodetect python for '$2'"
        return 1
    fi

    local version="$(py.ver $python)"
    if [[ "$2" =~ ^[0-9]\.[0-9]+$ ]] || [ "$2" = "2" ] || [ "$2" = "3" ]; then
        local packages="${@:3}"
    else
        local packages="${@:2}"
    fi

    local venv="$(venv.off)"
    local using="$(py.ver)"

    if [ -z "$using" ]; then
        fail $0 "'$python'"
        [ -n "$venv" ] && source "$venv/bin/activate"
        return 1
    fi

    py.set "$python"
    if [ "$?" -gt 0 ]; then
        [ -n "$venv" ] && source "$venv/bin/activate"
        return 1
    fi

    if ! py.lib.exists 'virtualenv' "$python"; then
        info $0 "virtualenv isn't installed for `py.ver`, proceed"
        pip.install virtualenv

        if ! py.lib.exists 'virtualenv' "$python"; then
            fail $0 "something went wrong"
            py.set "$using"
            [ -n "$venv" ] && source "$venv/bin/activate"
            return 2
        fi
    fi

    local message="create env '$name' with $python ($version): $full"
    if [ -n "$packages" ]; then
        local message="$message (preinstalled packages: $packages)"
    fi

    if [[ "$version" =~ "^2" ]]; then
        local args_env='--pip="20.3.4"'
    else
        local args_pip='pip setuptools wheel'
    fi

    info $0 "$message"

    run_show "builtin cd "$root" && $(py.exe) -m virtualenv --python=$python $args_env "$full" && source "$full/bin/activate" && pip install --compile --no-input --prefer-binary --upgrade --upgrade-strategy=eager pipdeptree $args_pip $packages && builtin cd $cwd"

    local venv="$(venv.off)"
    py.set "$using"
    [ -n "$venv" ] && source "$venv/bin/activate"
    path.rehash
}

function venv.temp {
    local venv="$(temp.dir)/$(fs.basename "$ASH_PY_ENVS_ROOT")/$(get.name)"
    venv.make "$venv" $@
}

function venv.cd {
    local venv="$(venv.path $*)"
    if [ -n "$venv" ] && [ -d "$venv" ]; then
        builtin cd "$venv"
    else
        return 1
    fi
}

function venv.site {
    local cwd="$PWD"
    venv.cd $* || ([ $? -gt 0 ] && return 1)

    local env_site="$(find lib/ -maxdepth 1 -type d -name 'python*')"

    if [ -d "$env_site/site-packages" ]; then
        builtin cd "$env_site/site-packages"
        [ -n "${@:2}" ] && builtin cd "${@:2}"
    else
        fail $0 "something wrong for '$env_path', path: '$env_site'"
        builtin cd "$cwd"
    fi
}

function venv.temp.remove {
    local cwd="$PWD"
    venv.cd $* || ([ "$?" -gt 0 ] && return 1)

    local vwd="$PWD"
    local temp="$(venv.temp.dir)"

    if [[ ! $vwd =~ "^$temp" ]]; then
        fail $0 "DO NOT remove '$vwd' because isn't temporary"
        builtin cd $cwd
        return 1
    fi

    if [ "$VIRTUAL_ENV" = "$vwd" ]; then
        run_show "builtin cd $VIRTUAL_ENV/bin && source activate && deactivate && builtin cd .."
    fi
    run_show "rm -rf $vwd 2>/dev/null; builtin cd $cwd || builtin cd ~"
    path.rehash
}

# ———

function __widget.pip.freeze {
    source "$ASH/lib/python.sh"
    pip.exe || return 1

    local venv="$(fs.basename ${VIRTUAL_ENV:-''})"
    local preview="echo {2} | xargs -n 1 $SHELL $PIP_PKG_INFO"
    local value="$($SHELL -c "
        $SHELL $PIP_LIST_TOP \
        | $FZF \
            --multi \
            --nth=2 \
            --tiebreak='index' \
            --layout=reverse-list \
            --preview='$preview' \
            --prompt='packages $venv > ' \
            --preview-window="left:`misc.preview.width`:noborder" \
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
}
zle -N __widget.pip.freeze

# ———

if [ -d "$VIRTUAL_ENV" ]; then
    venv.path.activate "$VIRTUAL_ENV"
    path.rehash
fi

ASH_DEPRECATIONS[chdir_to_virtualenv]=venv.cd
ASH_DEPRECATIONS[chdir_to_virtualenv_stdlib]=venv.site
ASH_DEPRECATIONS[get_temporary_envs_directory]=venv.temp.dir
ASH_DEPRECATIONS[get_virtualenv_path]=venv.path
ASH_DEPRECATIONS[python_from_version]=py.from.version
ASH_DEPRECATIONS[virtualenv_activate]=venv.on
ASH_DEPRECATIONS[virtualenv_create]=venv.make
ASH_DEPRECATIONS[virtualenv_deactivate]=venv.off
ASH_DEPRECATIONS[virtualenv_node_deploy]=venv.node
ASH_DEPRECATIONS[virtualenv_path_activate]=venv.path.activate
ASH_DEPRECATIONS[virtualenv_temporary_create]=venv.temp
ASH_DEPRECATIONS[virtualenv_temporary_destroy]=venv.temp.remove
