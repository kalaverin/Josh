local THIS_DIR="$(fs.realdir "$0")"
local INCLUDE_DIR="$(fs.realpath $THIS_DIR/pip)"

local PIP_LIST_ALL="$INCLUDE_DIR/pip_list_all.sh"
local PIP_LIST_TOP="$INCLUDE_DIR/pip_list_top_level.sh"
local PIP_PKG_INFO="$INCLUDE_DIR/pip_pkg_info.sh"

# ———

function uv.make {
    local binaries=(
        direnv
        git
        python
        tree
        uv
    )
    local project

    if local missing="$(fs.lookup.missing "$binaries")" && [ -n "$missing" ]; then
        fail $0 "missing binaries: $missing"
        return 1
    fi

    project="$(get.name 1)" && \
    mkcd "$(temp.dir)/pet" && \
        git clone git@bitbucket.org:kalaverin/skel.git "$project" && \
        builtin cd "$project" && rm -rf .git/ && git init && \
        find . -type f -exec grep -Ilq "." {} \; -exec sed -i "s/Blank/$project/g" {} \; && \
        mv "src/blank" "src/$project" && \
    uv python pin 3.10 && \
        uv sync --all-extras && \
        uv lock && uv venv --refresh && \
    git add . && git commit -m "Start from scratch" && \
    direnv allow && \
    builtin cd "src/$project" && \
    tree ../../ && \
    py main.py
}

function venv.on {
    local venv="$(venv.path $*)"

    if [ -d "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" = "$venv" ]; then
        printf "$VIRTUAL_ENV"
        return 0
    fi

    if [ -n "$venv" ] && [ -d "$venv" ]; then
        venv.off >/dev/null
        source "$venv/bin/activate"
        local retval="$?"

        if [ "$retval" -gt 0 ]; then
            return "$retval"
        fi

        path.rehash
        printf "$VIRTUAL_ENV"
        return 0

    elif [ -z "$venv" ] && [ -n "$1" ]; then
        # when we trying to activate real env, but isn't found — it's error
        return 1
    fi
    return 2
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
    printf "$ASH_PY_TEMP_ENVS_ROOT"
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
        run.show "$pip install nodeenv" && venv.path.activate "$venv"
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
        run.show "nodeenv --python-virtualenv --node=$version"
        path.rehash
    fi
}

function venv.path {
    if [ "$1" ]; then
        if [ -d "$1" ] && [ -f "$1/bin/activate" ]; then
            printf "$1"

        elif [ -f "$ASH_PY_ENVS_ROOT/$1/bin/activate" ]; then
            printf "$ASH_PY_ENVS_ROOT/$1"

        else
            local temp="$(venv.temp.dir)"
            if [ -f "$temp/$1/bin/activate" ]; then
                printf "$temp/$1"
            else
                fail $0 "venv '$1' isn't found"
            fi
        fi

    elif [ -x "$VIRTUAL_ENV" ]; then
        printf "$VIRTUAL_ENV"
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
    printf "$python"
}

function __venv.process.packages.args {
    if [ -z "$1" ]; then
        fail $0 "empty \$1 workdir"
        return 1

    elif [ ! -d "$1" ]; then
        fail $0 "directory '$1' isn't accessible"
        return 2
    fi

    for item in $(echo "${@:2}" | sd ' +' '\n'); do
        if [ -f "$1/$item" ]; then
            echo "--requirement $(fs.realpath "$1/$item")"
        elif [ "$1" = '.' ]; then
            echo "$(fs.realpath "$1")"
        elif [ -f "$item/pyproject.toml" ]; then
            echo "$(fs.realpath "$item")"
        else
            echo "$item"
        fi
    done
}

function venv.make {
    local not_packages=()
    local offset=0

    local cwd="$PWD"
    local env="$VIRTUAL_ENV"

    local libdir python env_name env_path root version packages venv using upper

    local function return.restore () {
        builtin cd "$cwd"
        if [ -z "$env" ]; then
            venv.off >/dev/null
        elif [ -n "$env" ]; then
            venv.on "$env" >/dev/null
        fi
    }

    for item in $*; do
        let offset="$offset + 1"

        if [ -f "$item" ]; then
            continue
        fi

        if [[ "$item" =~ ^[0-9][0-9\.]*$ ]]; then
            python="$(fs.realpath `which "python$MATCH"`)"
            if [ "$?" -gt 0 ] || [ ! -x "$python" ]; then
                fail $0 "python binary '$python' ($item) doesn't exists or something wrong"
                return 3
            fi
            python="$(py.home "$python")/bin/python" || return "$?"
            fs.realpath "$python" 1>/dev/null || return "$?"
            not_packages+=($offset)

        elif [[ "$item" =~ '/' ]] || [[ "$item" =~ '.' ]]; then

            if [[ "$item" =~ '/' ]]; then
                local chunk="$item"
                while true; do
                    if [ -d "$chunk" ] && [ ! "$chunk" = '.' ]; then
                        env_path="$item"
                        env_name="$(fs.basename "$env_path")" || return "$?"
                        not_packages+=($offset)
                        break
                    fi
                    parent="$(fs.dirname "$chunk")" || return "$?"
                    [ -z "$parent" ] || [ "$parent" = "$chunk" ] && break
                    chunk="$parent"
                done

            else
                env_name="$(fs.basename "$item")" || return "$?"
                env_path="$(fs.realpath "$PWD")/$item" || return "$?"
                not_packages+=($offset)
            fi

        # elif [[ "$item" =~ ^/.+/[0-9a-z]+[0-9a-z\.-]*[0-9a-z]+$ ]]; then
        fi
    done

    if [ -z "$env_name" ] && [ ! -f "$1" ] ; then
        if [ "${not_packages[(Ie)1]}" -eq 0 ]; then
            not_packages+=(1)
            env_name="$1"
        fi
    fi

    if [ -z "$env_path" ] && [ -n "$env_name" ]; then
        env_path="$ASH_PY_ENVS_ROOT/$env_name"
    fi

    if [ ! -x "$python" ]; then
        python="$(py.exe)"
    fi

    local offset=0
    local packages=()

    for item in $*; do
        let offset="$offset + 1"
        if [ "${not_packages[(Ie)$offset]}" -eq 0 ]; then
            packages+=($item)
        fi
    done

    version="$(py.ver.full.raw "$python")"
    packages="$(__venv.process.packages.args "$cwd" "$packages" | sed -z 's:\n: :g' | sed 's/ *$//' )"

    if [ -z "$env_name" ]; then
        fail $0 "environment name empty"
        return.restore
        return 1

    elif [ ! -x "$python" ]; then

        fail $0 "'$python' isn't correct (accessible, executable) python executable path"
        return.restore
        return 1

    elif [ -z "$version" ]; then
        fail $0 "'$version' isn't correct python version"
        return.restore
        return 1

    fi

    root="$(fs.dirname "$env_path")"
    if [ ! -d "$root" ]; then
        mkdir -p "$root"

    elif [ -d "$env_path" ]; then
        fail $0 "env_name '$env_name' already exists in '$root'"
        return.restore
        return 2
    fi

    venv="$(venv.off)"
    using="$(py.ver)"

    if [ -z "$using" ]; then
        fail $0 "'$python'"
        return.restore
        return 5
    fi

    py.set "$python"
    if [ "$?" -gt 0 ]; then
        return.restore
        return 6
    fi

    if ! py.lib.exists 'pip' "$python"; then
        info $0 "pip isn't installed for $(py.ver), proceed"
        pip.deploy "$python" && path.rehash

        if ! py.lib.exists 'pip' "$python"; then
            fail $0 "something went wrong when pip deploy"
            py.set "$using"
            return.restore
            return 7
        fi
    fi

    if ! py.lib.exists 'virtualenv' "$python"; then
        info $0 "virtualenv isn't installed for $(py.ver), proceed"
        pip.install virtualenv && path.rehash

        if ! py.lib.exists 'virtualenv' "$python"; then
            fail $0 "something went wrong when virtualenv install"
            py.set "$using"
            return.restore
            return 7
        fi
    fi

    local message="create env '$env_name' with $python ($version): $env_path"
    if [ -n "$packages" ]; then
        local message="$message (preinstalled packages: $packages)"
    fi

    if [[ "$version" =~ "^2" ]]; then
        local args_env='--pip="20.3.4"'
    else
        local args_pip='pip setuptools wheel'
    fi

    info $0 "$message"

    run.show "builtin cd "$root" && $(py.exe "$python") -m virtualenv --symlink-app-data --python=$python $args_env "$env_path" && source "$env_path/bin/activate" && pip install --compile --no-input --prefer-binary --upgrade --upgrade-strategy=eager pipdeptree pysnooper $args_pip $packages && builtin cd $cwd"

    libdir="$(find "$env_path/lib/" -maxdepth 1 -type d -name 'python*')"
    if [ "$?" -eq 0 ]; then
        libdir="$(fs.realpath "$libdir")"
        if [ "$?" -eq 0 ]; then
            ln -s "$libdir/site-packages" "$env_path/site"
            ln -s "$libdir/dist-packages" "$env_path/dist"
        fi
    fi
    echo "layout virtualenv .">"$env_path/.envrc"
    direnv allow "$env_path"

    local venv="$(venv.off)"
    py.set "$using"
    [ -n "$venv" ] && source "$venv/bin/activate"
    path.rehash
    builtin cd "$cwd"
}

function venv.temp {
    local venv="$(temp.dir)/$(fs.basename "$ASH_PY_ENVS_ROOT")/$(get.name)"
    venv.make "$venv" $@
}

function venv.cd {
    local venv
    venv="$(venv.path $*)"
    if [ -n "$venv" ] && [ -d "$venv" ]; then
        builtin cd "$venv"
    else
        return 1
    fi
}

function venv.site {
    local env_site venv
    local cwd="$PWD"
    venv="$(venv.path $*)"

    if [ "$?" -gt 0 ] || [ ! -x "$venv" ]; then
        return 1
    fi

    root="$(find "$venv/lib/" -maxdepth 1 -type d -name 'python*')"
    if [ "$?" -gt 0 ] || [ ! -x "$root" ]; then
        return 2
    fi

    if [ -x "$root/site-packages" ]; then
        builtin cd "$root/site-packages"
        [ "${@:2}" ] && [ -d "${@:2}" ] && builtin cd "${@:2}"
    else
        fail $0 "something wrong for '$venv', path: '$root'"
        builtin cd "$cwd"
    fi
}

function venv.temp.remove {
    local cwd="$PWD"

    if [ -z "$VIRTUAL_ENV" ] || [ ! -x "$VIRTUAL_ENV" ]; then
        fail $0 "couldn't find active environment"
        return 1
    fi
    venv.cd $* || ([ "$?" -gt 0 ] && return 1)

    #

    local temp="$(temp.dir)"
    if [[ ! $PWD =~ "^$temp" ]]; then
        fail $0 "DO NOT remove '$PWD' because isn't temporary"
        builtin cd $cwd
        return 1
    fi

    #

    if [ "$VIRTUAL_ENV" = "$PWD" ]; then
        run.show "builtin cd $VIRTUAL_ENV/bin && source activate && deactivate && builtin cd .."
    else
        fail $0 "can't chdir to $VIRTUAL_ENV"
        return 1
    fi

    #

    if [ "$cwd" = "$PWD" ]; then
        builtin cd ~
    fi
    run.show "rm -rf $VIRTUAL_ENV 2>/dev/null; builtin cd $cwd || builtin cd ~"
    path.rehash
}

# ———

function __widget.pip.freeze {
    source "$ASH/lib/python.sh"
    pip.exe || return 1

    local venv="$(fs.basename ${VIRTUAL_ENV:-''})"
    local preview="printf {2} | xargs -n 1 $SHELL $PIP_PKG_INFO"
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
