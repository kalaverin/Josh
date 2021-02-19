find `git rev-parse --quiet --show-toplevel` -type f | grep setup.cfg | awk '{ print length($0) " " $0; }' $file | sort -n | cut -d ' ' -f 2- | head -n 1 | xargs dirname 2>/dev/null
