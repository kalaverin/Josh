# git status --porcelain --ignore-submodules --no-ahead-behind --untracked-files | awk 'match($1, "^\\?\\?$"){print $2}' | awk '{$1=$1};1'
git ls-files --deleted --others --exclude-standard `git rev-parse --show-toplevel`
