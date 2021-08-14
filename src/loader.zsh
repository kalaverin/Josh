source "$ZSH/custom/plugins/forgit/forgit.plugin.zsh"
source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-fuzzy-search-and-edit/plugin.zsh"
source "$ZSH/custom/plugins/emoji-cli/emoji-cli.zsh"
source "$ZSH/custom/plugins/zsh-plugin-fzf-finder/fzf-finder.plugin.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting-filetypes/zsh-syntax-highlighting-filetypes.zsh"

source "$JOSH/src/completion.zsh"
source "$JOSH/src/options.zsh"

source "$JOSH/usr/aliases.zsh"
source "$JOSH/usr/bindings.zsh"
source "$JOSH/usr/common.zsh"

source "$JOSH/usr/units/git.zsh"
source "$JOSH/usr/units/python.zsh"
source "$JOSH/usr/units/files.zsh"

local unified_path="$(echo "$PATH" | sd ':' '\n' | runiq - | xargs -n 1 realpath 2>/dev/null | sd '\n' ':' | sd '(^:|:$)' '')"
[ "$?" = 0 ] && [ "$unified_path " ] && export PATH="$unified_path"
