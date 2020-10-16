xargs -I^^ git log --simplify-by-decoration --decorate --pretty=oneline --color=always --format='%C(auto)%d%C(reset) %s %C(black)%C(bold)%ae %cr' ^^ | grep -P '(tag: |HEAD)' $@
