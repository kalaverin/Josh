typeset -Agx JOSH_DEPRECATIONS=()

source "$JOSH/usr/aliases.zsh"
source "$JOSH/usr/common.zsh"

[ -x "$commands[tmux]" ] && source "$JOSH/usr/units/tmux.zsh"

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

[ -x "$commands[git]" ]    && source "$JOSH/usr/units/git.zsh"
[ -x "$commands[python]" ] && source "$JOSH/usr/units/python.zsh"

source "$JOSH/usr/update.zsh"
is_workhours || motd

source "$JOSH/src/plugins.zsh"
plugins_autoload

if [ -n "$JOSH_DEPRECATIONS" ]; then
    for deprecated func in ${(kv)JOSH_DEPRECATIONS}; do
        eval {"$deprecated() { depr \$0 \"deprecated and must be removed, use '$func' instead\"; $func \$* }"}
    done
fi
