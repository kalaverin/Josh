function pip_show() {
    local pip="`which -p pip`"
    [ ! -f "$pip" ] && return 1
    PIP_REQUIRE_VIRTUALENV=false python -m pip show $@ 2>&1 | grep -v 'DEPRECATION:' | grep -Pv '^(Require:|License:)'
    return 0
}

function pipdeptree_depends() {
    [ ! -f "`which -p pipdeptree`" ] && return 1
    local result="`pipdeptree -e pipdeptree,setuptools,pkg_resources,wheel -w silence -p $@ | grep -Pv "^($@)" | sd '^(\s+)(-\s+)' '$1' | sd ' \[required: (.+), installed: (.+)\]' '==$2 ($1)' | sd '\(Any\)' '~'`"
    [ "$result" ] && echo "Requires:\n$result"
    return 0
}

function pipdeptree_depends_reverse() {
    [ ! -f "`which -p pipdeptree`" ] && return 1
    local result="`pipdeptree -e pipdeptree,setuptools,pkg_resources,wheel -w silence -r -p $@ | grep -Pv "^($@)" | sd '^(\s+)(-\s+)' '$1' | sd ' \[requires: (.+)\]' ' || $1' | tabulate -d '||'`"
    [ "$result" ] && echo "Required by:\n$result"
    return 0
}

pip_show $@ && (pipdeptree_depends $@ & pipdeptree_depends_reverse $@)
