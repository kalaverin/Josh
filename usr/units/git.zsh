local THIS_DIR="`fs.realdir "$0"`"
local INCLUDE_DIR="`fs.realpath $THIS_DIR/git`"

local DIFF_FROM_TAG="$INCLUDE_DIR/git_diff_from_tag.sh"
local LIST_BRANCHES="$INCLUDE_DIR/git_list_branches.sh"
local SETUPCFG_LOOKUP="$INCLUDE_DIR/git_search_setupcfg.sh"
local TAG_FROM_STRING="$INCLUDE_DIR/git_tag_from_str.sh"

local DIFF_SHOW="$INCLUDE_DIR/git_show_diff.sh"
local DIFF_SHOW_PLEASE="$INCLUDE_DIR/git_show_file_diff.sh"
local DIFF_SHOW_OR_CONTENT="$INCLUDE_DIR/show_file_diff_or_content.sh"


local LIST_TO_ADD="git status --short --verbose --no-ahead-behind --ignore-submodules --untracked-file"
local ESCAPE_STATUS='sd "^( )" "." | sd "^(.)( )" "$1." | sd "^(. )" "++ "'
local GIT_DIFF="git diff --color=always --patch --stat --diff-algorithm=histogram"

# ———

GIT_LIST_FORMAT="%C(reset)%C(green)%C(dim)%h%C(auto)%d %C(reset)%s %C(brightblack)%C(dim)%an %C(black)%>(512)%>(32,trunc)%H%C(reset)%C(brightblack)%C(dim)"

CMD_EXTRACT_COMMIT="grep -o '[a-f0-9]\{32,\}$'"
CMD_EXTRACT_TOP_COMMIT="head -1 | grep -o '[a-f0-9]\{32,\}$'"

CMD_DELTA="$DELTA --paging='always'"
CMD_SHOW_ARGS="--first-parent --find-renames --find-copies --format='format:%H %ad%n%an <%ae>%n%s' --diff-algorithm=histogram $ | $DELTA"
CMD_XARGS_SHOW_TO_COMMIT="xargs -I$ git show -m $CMD_SHOW_ARGS"
CMD_XARGS_DIFF_TO_COMMIT="xargs -I$ git diff -m $CMD_SHOW_ARGS"

alias git_list_commits="git log --color=always --format='$GIT_LIST_FORMAT' --first-parent"
alias git_list_tags="git log --color=always --format='$GIT_LIST_FORMAT' --tags --no-walk"

alias -g GLOB_PIPE_REMOVE_DOTS="sed -re 's/(\.{2,})+$//g'"
alias -g GLOB_PIPE_REMOVE_SPACES="sed -re 's/(\\s+)/ /g' | sd '^\s+' ''"
alias -g GLOB_PIPE_NUMERATE="awk '{print NR,\$0}'"

# ——— required

source "$INCLUDE_DIR/functions.zsh"
source "$INCLUDE_DIR/widgets.zsh"
source "$INCLUDE_DIR/binds.zsh"

# ——— simple helpers

function git_abort {
    local state
    state="$(git.this.state)" || return 0 # merge, rebase or cherry-pick
    [ "$state" ] && git "$state" --abort
    zle reset-prompt
}
zle -N git_abort

function git_continue {
    local state
    state="$(git.this.state)" || return 0 # merge, rebase or cherry-pick
    [ "$state" ] && git "$state" --continue
    zle reset-prompt
}
zle -N git_continue

function open_editor_on_conflict {
    local line
    line="$(grep -P --line-number --max-count=1 '^=======' "$1" | tabulate -d ':' -i 1)"
    if [ "$line" -gt 0 ]; then
        run.show "micro $* +$line"
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
