xargs -I^^ git ls-tree -r --name-only ^^ | runiq - | sort
