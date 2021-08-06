source "$ZSH/custom/plugins/forgit/forgit.plugin.zsh"
source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-fuzzy-search-and-edit/plugin.zsh"
source "$ZSH/custom/plugins/emoji-cli/emoji-cli.zsh"
source "$ZSH/custom/plugins/zsh-plugin-fzf-finder/fzf-finder.plugin.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting-filetypes/zsh-syntax-highlighting-filetypes.zsh"

source "$JOSH/sources/aliases.zsh"
source "$JOSH/sources/completion.zsh"
source "$JOSH/sources/urlencode.zsh"
source "$JOSH/sources/functions.zsh"
source "$JOSH/sources/bindings.zsh"

source "$JOSH/sources/functions/git.zsh"
source "$JOSH/sources/functions/python.zsh"
source "$JOSH/sources/functions/utils.zsh"

unsetopt correct_all
unsetopt correct

if [ -f "`which -p scotty`" ]; then
    eval "$(scotty init zsh)"
fi

if [ -f "`which -p starship`" ]; then
    eval "$(starship init zsh)"
fi

if [ -f "`which -p pip`" ]; then
    eval "$(pip completion --zsh)"
fi
