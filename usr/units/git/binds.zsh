#              alt-q, commits history
bindkey "\eq"  __widget.git.show_commits
#              shift-alt-q, branch -> history
bindkey "^[Q"  __widget.git.select_branch_with_callback
#              ctrl-q, file -> history
bindkey "^q"   __widget.git.select_file_show_commits
#              ctrl-alt-q, branch -> file -> history
bindkey "\e^q" __widget.git.select_branch_then_file_show_commits

#              alt-a, git add
bindkey "\ea"  __widget.git.add
#              shift-alt-a, checkout to active branch last commit
bindkey "^[A"  __widget.git.checkout_modified
#              ctrl-a, select file, then select commit for checkout and checkout it
bindkey "^a"   __widget.git.select_commit_from_file
#              ctrl-alt-a, on active branch, select commit, checkout files
bindkey "\e^a" __widget.git.select_files_from_commit

#              alt-s, go to branch
bindkey "\es"  __widget.git.switch_branch
#              shift-alt-a, fetch another and merge branch
bindkey "^[S"  __widget.git.rebase_branch
#              ctrl-s, go to commit
bindkey "^s"   __widget.git.checkout_commit
#              ctrl-alt-a, go to tag
bindkey "\e^s" __widget.git.checkout_tag

#              alt-f, fetch remote branch and, if possible, checkout to + pull
bindkey "\ef"  __widget.git.fetch_branch
#              shift-alt-f, delete local branch
bindkey "^[F"  __widget.git.delete_remote_branch
#              ctrl-f, delete local branch
bindkey "^f"   __widget.git.delete_local_branch
#              ctrl-alt-f, permanently delete REMOTE branch
bindkey "\e^f" __widget.git.delete_branch  # PUSH TO origin, caution!

#              alt-p, experimental conflict solver
bindkey "\ep"  __widget.git.squash_to_commit
#              shift-alt-p, squash all
bindkey "^[P"  __widget.git.replace_all_commits_with_one
#              ctrl-p, git abort
bindkey "^p"   git_abort

bindkey "^o"   git_continue
