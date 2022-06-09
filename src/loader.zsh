source "$JOSH/usr/aliases.zsh"
source "$JOSH/usr/common.zsh"

[ -x "$(which tmux)" ] && source "$JOSH/usr/units/tmux.zsh"

source "$ZSH/custom/plugins/forgit/forgit.plugin.zsh"
source "$ZSH/custom/plugins/ondir/scripts.zsh"
source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-fuzzy-search-and-edit/plugin.zsh"
source "$ZSH/custom/plugins/zsh-plugin-fzf-finder/fzf-finder.plugin.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting-filetypes/zsh-syntax-highlighting-filetypes.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

source "$JOSH/src/options.zsh"
source "$JOSH/src/completion.zsh"
source "$JOSH/usr/bindings.zsh"
source "$JOSH/usr/units/files.zsh"
source "$JOSH/usr/deprecated.zsh"

[ -x "$(which git)" ]    && source "$JOSH/usr/units/git.zsh"
[ -x "$(which python)" ] && source "$JOSH/usr/units/python.zsh"

source "$JOSH/usr/update.zsh"
is_workhours || motd

source "$JOSH/src/plugins.zsh"
plugins_autoload
