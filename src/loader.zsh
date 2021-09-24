source "$ZSH/custom/plugins/ondir/scripts.zsh"
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

local branch="`josh_branch`"
if [ -z "$branch" ]; then
    echo " - Josh branch couldn't detected, something wrong!"

elif [ ! "$branch" = 'master' ]; then
    local last_commit="$(
        git --git-dir="$JOSH/.git" --work-tree="$JOSH/" \
        log -1 --format="at %h updated %cr" 2>/dev/null
    )"
    echo " + Josh $branch $last_commit."
fi
