git status --porcelain --ignore-submodules --no-ahead-behind --untracked-files | awk 'match($1, "^\\?\\?$"){print $2}' | sort | uniq
