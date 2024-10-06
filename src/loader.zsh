if [ -z "$ASH_DEPRECATIONS" ]; then
    typeset -Agx ASH_DEPRECATIONS=()
fi

path.rehash

source "$ASH/lib/shared.sh"
source "$ASH/usr/aliases.zsh"
source "$ASH/usr/common.zsh"

[ -x "$commands[tmux]" ] && source "$ASH/usr/units/tmux.zsh"

source "$ZSH/custom/plugins/forgit/forgit.plugin.zsh"
source "$ZSH/custom/plugins/zsh-async/async.zsh"
source "$ZSH/custom/plugins/zsh-fuzzy-search-and-edit/plugin.zsh"
source "$ZSH/custom/plugins/zsh-plugin-fzf-finder/fzf-finder.plugin.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting-filetypes/zsh-syntax-highlighting-filetypes.zsh"
source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

source "$ASH/src/options.zsh"
source "$ASH/src/completion.zsh"
source "$ASH/usr/bindings.zsh"
source "$ASH/usr/units/files.zsh"

[ -x "$commands[git]" ]    && source "$ASH/usr/units/git.zsh"
[ -x "$commands[python]" ] && source "$ASH/usr/units/python.zsh"

source "$ASH/usr/update.zsh"
is_workhours || motd

source "$ASH/src/plugins.zsh"
plugins_autoload

if [ -n "$ASH_DEPRECATIONS" ]; then
    for deprecated func in ${(kv)ASH_DEPRECATIONS}; do
        eval {"$deprecated() { depr \$0 \"deprecated and must be removed, use '$func' instead\"; $func \$* }"}
    done
fi
