PIP_REQUIRE_VIRTUALENV=false \
    pip freeze 2>/dev/null | \
        grep -Pv '^(\s*#)' | \
        grep -Pv '^(-\w )' | \
        grep -Po '^([^\s]+)' |
        grep -Pv '^(pipdeptree|setuptools|pkg_resources|wheel|pip-chill)' | \
        tabulate -d '=='
