PIPDEP_DEFAULT_OPTS="-e pipdeptree,setuptools,pkg_resources,wheel,pip-chill -w silence"

function pip_show() {
    local pip="`which -p pip`"
    [ ! -f "$pip" ] && return 1
    pip show $@ | grep -Pv '^(Require)'
    return 0
}


function pipdeptree_depends() {
    [ ! -f "`which -p pipdeptree`" ] && return 1
    local pipdeptree="`pipdeptree -e pipdeptree,setuptools,pkg_resources,wheel -w silence -p $@ | grep -Pv "^($@)" | sd '^(\s+)(-\s+)' '$1' | sd ' \[required: (.+), installed: (.+)\]' '==$2 ($1)' | sd '\(Any\)' '~'`"
    [ "$pipdeptree" ] && echo "Requires:\n$pipdeptree"
    return 0
}


function pipdeptree_depends_reverse() {
    [ ! -f "`which -p pipdeptree`" ] && return 1
    local pipdeptree="`pipdeptree -e pipdeptree,setuptools,pkg_resources,wheel -w silence -r -p $@ | grep -Pv "^($@)" | sd '^(\s+)(-\s+)' '$1' | sd ' \[requires: (.+)\]' ' || $1' | tabulate -d '||'`"
    [ "$pipdeptree" ] && echo "Required by:\n$pipdeptree"
    return 0
}

pip_show $@ && (pipdeptree_depends $@ & pipdeptree_depends_reverse $@)
