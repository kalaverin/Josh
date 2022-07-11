local THIS_DIR="`fs.realdir "$0"`"
local INCLUDE_DIR="`fs.realpath $THIS_DIR/git`"

local DIFF_FROM_TAG="$INCLUDE_DIR/git_diff_from_tag.sh"
local LIST_BRANCHES="$INCLUDE_DIR/git_list_branches.sh"
local SETUPCFG_LOOKUP="$INCLUDE_DIR/git_search_setupcfg.sh"
local TAG_FROM_STRING="$INCLUDE_DIR/git_tag_from_str.sh"
local LIST_TO_ADD="git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file"
local ESCAPE_STATUS='sd "^( )" "." | sd "^(.)( )" "$1." | sd "^(. )" "++ "'
local GIT_DIFF="git diff --color=always --patch --stat --diff-algorithm=histogram"


# ———

alias git_list_commits="git log --color=always --format='%C(auto)%D %C(reset)%s %C(black)%C(bold)%ae %cr %<(12,trunc)%H' --first-parent"
alias -g pipe_remove_dots_and_spaces="sed -re 's/(\.{2,})+$//g' | sed -re 's/(\\s+)/ /g' | sd '^\s+' ''"
alias -g pipe_numerate="awk '{print NR,\$0}'"

DELTA_FOR_COMMITS_LIST_OUT="xargs -I$ git show --find-renames --find-copies --format='format:%H %ad%n%an <%ae>%n%s' --diff-algorithm=histogram $ | $DELTA --paging='always'"

# ——— required

source "$INCLUDE_DIR/functions.zsh"
source "$INCLUDE_DIR/widgets.zsh"
source "$INCLUDE_DIR/binds.zsh"

# ——— simple helpers

function git_abort {
    local state
    state="$(git.this.state)"  # merge, rebase or cherry-pick
    [ "$?" -gt 0 ] && return 0
    [ "$state" ] && git "$state" --abort
    zle reset-prompt
}
zle -N git_abort

function open_editor_on_conflict {
    local line
    line="$(grep -P --line-number --max-count=1 '^=======' "$1" | tabulate -d ':' -i 1)"
    if [ "$line" -gt 0 ]; then
        $EDITOR $* +$line
        return "$?"
    fi
}

function git_autoaccept {
    local state
    if [ "$1" = 'theirs' ] || [ "$1" = 'ours' ]; then
        state="$(git.this.state)"  # merge, rebase or cherry-pick
        [ "$?" -gt 0 ] && return 0

        run.show "git checkout --$1 . && git $state --skip"
        if [ "$?" -eq 128 ]; then
            git_autoaccept "$1"
        else
            return 0
        fi
    fi
}

ASH_DEPRECATIONS[DROP_THIS_BRANCH_RIGHT_NOW]=git.branch.DELETE.REMOTE
ASH_DEPRECATIONS[cmd_git_checkout]=git.cmd.checkout
ASH_DEPRECATIONS[cmd_git_fetch]=git.cmd.fetch
ASH_DEPRECATIONS[cmd_git_pull]=git.cmd.pull
ASH_DEPRECATIONS[cmd_git_pull_merge]=git.cmd.pullmerge
ASH_DEPRECATIONS[drop_this_branch_right_now]=git.branch.delete
ASH_DEPRECATIONS[get_repository_state]=git.this.state
ASH_DEPRECATIONS[git_branch_delete]=git.branch.delete.force
ASH_DEPRECATIONS[git_branch_rename]=git.branch.rename
ASH_DEPRECATIONS[git_checkout_from_actual]=git.checkout.actual
ASH_DEPRECATIONS[git_checkout_from_current]=git.checkout.current
ASH_DEPRECATIONS[git_current_branch]=git.this.branch
ASH_DEPRECATIONS[git_current_hash]=git.this.hash
ASH_DEPRECATIONS[git_fetch]=git.fetch
ASH_DEPRECATIONS[git_fetch_checkout_branch]=git.branch.select
ASH_DEPRECATIONS[git_fetch_merge]=git.fetch.merge
ASH_DEPRECATIONS[git_pull]=git.pull
ASH_DEPRECATIONS[git_pull_merge]=git.pull.merge
ASH_DEPRECATIONS[git_pull_reset]=git.pull.reset
ASH_DEPRECATIONS[git_push]=git.push
ASH_DEPRECATIONS[git_push_force]=git.push.force
ASH_DEPRECATIONS[git_repository_clean]=git.is_clean
ASH_DEPRECATIONS[git_rewind_time]=git.mtime.set
ASH_DEPRECATIONS[git_root]=git.this.root
ASH_DEPRECATIONS[git_set_branch_tag]=git.branch.tag
ASH_DEPRECATIONS[git_set_tag]=git.tag.set
ASH_DEPRECATIONS[git_squash_already_pushed]=git.squash.pushed
ASH_DEPRECATIONS[git_unset_tag]=git.tag.unset
ASH_DEPRECATIONS[is_repository_clean]=git.is_clean
