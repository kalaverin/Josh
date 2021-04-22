source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-abbr-path/.abbr_pwd"
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
setupsolarized dircolors.256dark
