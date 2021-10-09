local command="pipdeptree --all --warn silence --exclude pip,pipdeptree,setuptools,pkg_resources,wheel"
[ ! -d "$VIRTUAL_ENV" ] && local command="$command --user-only"

$SHELL -c "$command" \
    | grep -Po '^([^\s]+)' \
    | sd '^(.+)==(.+)$' '$2\t$1' \
    | sort -k 2 | column -t
