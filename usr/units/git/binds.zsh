#              alt-q, commits history
bindkey "\eq"  git_widget_show_commits
#              shift-alt-q, branch -> history
bindkey "^[Q"  git_widget_select_branch_with_callback
#              ctrl-q, file -> history
bindkey "^q"   git_widget_select_file_show_commits
#              ctrl-alt-q, branch -> file -> history
bindkey "\e^q" git_widget_select_branch_then_file_show_commits

#              alt-a, git add
bindkey "\ea"  git_widget_add
#              shift-alt-a, checkout to active branch last commit
bindkey "^[A"  git_widget_checkout_modified
#              ctrl-a, on active branch, select commit, checkout files
bindkey "^a"   git_widget_select_commit_then_files_checkout
#              ctrl-alt-a, select branch, select commit, checkout files
bindkey "\e^a" git_widget_select_branch_then_commit_then_file_checkout

#              alt-s, go to branch
bindkey "\es"  git_widget_checkout_branch
#              shift-alt-a, fetch another and merge branch
bindkey "^[S"  git_widget_rebase_branch
#              ctrl-s, go to commit
bindkey "^s"   git_widget_checkout_commit
#              ctrl-alt-a, go to tag
bindkey "\e^s" git_widget_checkout_tag

#              alt-f, fetch remote branch and, if possible, checkout to + pull
bindkey "\ef"  git_widget_fetch_branch
#              shift-alt-f, delete local branch
bindkey "^[F"  git_widget_delete_branch
#              ctrl-alt-a, permanently delete REMOTE branch
bindkey "\e^f" git_widget_delete_remote_branch  # PUSH TO origin, caution!

#              alt-p, experimental conflict solver
bindkey "\ep"  git_widget_conflict_solver
#              shift-alt-p, squash all
bindkey "^[P"  git_replace_all_commits_with_one
#              ctrl-p, git abort
bindkey "^p"   git_abort
