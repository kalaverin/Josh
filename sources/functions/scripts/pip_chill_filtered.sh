pip-chill | \
    grep -Pv '^(\s*#)' | \
    grep -Pv '^(-\w )' | \
    grep -Po '^([^\s]+)' |
    grep -Pv '^(pipdeptree|setuptools|pkg_resources|wheel|pip-chill|python)=' | \
    tabulate -d '=='
