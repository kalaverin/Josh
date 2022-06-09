function cmd_git_checkout {
    warn $0 "deprecated, use: git.cmd.checkout"
    git.cmd.checkout $*
}
function cmd_git_fetch {
    warn $0 "deprecated, use: git.cmd.fetch"
    git.cmd.fetch $*
}
function cmd_git_pull {
    warn $0 "deprecated, use: git.cmd.pull"
    git.cmd.pull $*
}
function cmd_git_pull_merge {
    warn $0 "deprecated, use: git.cmd.pullmerge"
    git.cmd.pullmerge $*
}
function git_root {
    warn $0 "deprecated, use: git.this.root"
    git.this.root $*
}
function git_current_hash {
    warn $0 "deprecated, use: git.this.hash"
    git.this.hash $*
}
function git_current_branch {
    warn $0 "deprecated, use: git.this.branch"
    git.this.branch $*
}
function get_repository_state {
    warn $0 "deprecated, use: git.this.state"
    git.this.state $*
}
function git_branch_delete {
    warn $0 "deprecated, use: git.branch.delete.force"
    git_branch_delete.force $*
}
function git_branch_rename {
    warn $0 "deprecated, use: git.branch.rename"
    git_branch_rename $*
}
function git_checkout_from_actual {
    warn $0 "deprecated, use: git.checkout.actual"
    git_checkout_from_actual $*
}
function git_checkout_from_current {
    warn $0 "deprecated, use: git.checkout.current"
    git_checkout_from_current $*
}
function git_fetch {
    warn $0 "deprecated, use: git.fetch"
    git.fetch $*
}
function git_fetch_merge {
    warn $0 "deprecated, use: git.fetch.merge"
    git.fetch.merge $*
}
function git_fetch_checkout_branch {
    warn $0 "deprecated, use: git.branch.select"
    git.branch.select $*
}
function git_set_branch_tag {
    warn $0 "deprecated, use: git.branch.tag"
    git.branch.tag $*
}
function git_pull {
    warn $0 "deprecated, use: git.pull"
    git.pull $*
}
function git_pull_merge {
    warn $0 "deprecated, use: git.pull.merge"
    git.pull.merge $*
}
function git_pull_reset {
    warn $0 "deprecated, use: git.pull.reset"
    git.pull.reset $*
}
function git_push {
    warn $0 "deprecated, use: git.push"
    git.push $*
}
function git_push_force {
    warn $0 "deprecated, use: git.push.force"
    git.push.force $*
}
function git_rewind_time {
    warn $0 "deprecated, use: git.mtime.set"
    git.mtime.set $*
}
function git_repository_clean {
    warn $0 "deprecated, use: git.is_clean"
    git.is_clean $*
}
function git_set_tag {
    warn $0 "deprecated, use: git.tah.set"
    git.tah.set $*
}
function git_unset_tag {
    warn $0 "deprecated, use: git.tag.unset"
    git.tag.unset $*
}
function drop_this_branch_right_now {
    warn $0 "deprecated, use: git.branch.delete"
    git.branch.delete $*
}
function DROP_THIS_BRANCH_RIGHT_NOW {
    warn $0 "deprecated, use: git.branch.DELETE.REMOTE"
    git.branch.DELETE.REMOTE $*
}
function git_squash_already_pushed {
    warn $0 "deprecated, use: git.squash.pushed"
    git.squash.pushed $*
}
