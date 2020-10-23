xargs -I^^ git ls-tree -r --name-only ^^ | uniq | sort
