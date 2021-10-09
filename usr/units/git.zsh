source "$JOSH/lib/shared.sh"

# ———

local THIS_DIR=`dirname "$(readlink -f "$0")"`
local INCLUDE_DIR="`realpath $THIS_DIR/git`"

local DIFF_FROM_TAG="$INCLUDE_DIR/git_diff_from_tag.sh"
local LIST_BRANCHES="$INCLUDE_DIR/git_list_branches.sh"
local SETUPCFG_LOOKUP="$INCLUDE_DIR/git_search_setupcfg.sh"
local TAG_FROM_STRING="$INCLUDE_DIR/git_tag_from_str.sh"
local LIST_TO_ADD="git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file"
local ESCAPE_STATUS='sd "^( )" "." | sd "^(.)( )" "$1." | sd "^(. )" "++ "'
local GIT_DIFF="git diff --color=always --stat --patch --diff-algorithm=histogram"

# ———

alias git_list_commits="git log --color=always --format='%C(auto)%D %C(reset)%s %C(black)%C(bold)%ae %cr %<(12,trunc)%H' --first-parent"
alias -g pipe_remove_dots_and_spaces="sed -re 's/(\.{2,})+$//g' | sed -re 's/(\\s+)/ /g' | sd '^\s+' ''"
alias -g pipe_numerate="awk '{print NR,\$0}'"

DELTA_FOR_COMMITS_LIST_OUT="xargs -I$ git show --find-renames --find-copies --function-context --format='format:%H %ad%n%an <%ae>%n%s' --diff-algorithm=histogram $ | $DELTA --paging='always'"

# ——— required

source "$INCLUDE_DIR/functions.zsh"
source "$INCLUDE_DIR/widgets.zsh"
source "$INCLUDE_DIR/binds.zsh"

# ——— simple helpers

function git_abort() {
    local state="`get_repository_state`"  # merge, rebase or cherry-pick
    [ "$?" -gt 0 ] && return 0
    [ "$state" ] && $SHELL -c "git $state --abort"
    zle reset-prompt
}
zle -N git_abort

function open_editor_on_conflict() {
    local line="$($SHELL -c "
        grep -P --line-number --max-count=1 '^=======' $1 | tabulate -d ':' -i 1
    ")"
    if [ "$line" -gt 0 ]; then
        $EDITOR $* +$line
        return $?
    fi
}

function chdir_to_setupcfg {
    if [ ! -f 'setup.cfg' ]; then
        local root=`cat "$SETUPCFG_LOOKUP" | $SHELL`
        if [ "$root" = "" ]; then
            echo " - setup.cfg not found in $cwd" 1>&2
            return 1
        fi
        builtin cd $root
    fi
    return 0
}
