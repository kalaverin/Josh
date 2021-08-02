# Key bindings
# http://zsh.sourceforge.net/Doc/Release/Expansion.html
# ------------
if [[ $- == *i* ]]; then

# insert
bindkey "${terminfo[kich1]}" overwrite-mode

# left and right
bindkey "^[OC"             forward-char
bindkey "$terminfo[kcuf1]" forward-char
bindkey "^[OD"             backward-char
bindkey "$terminfo[kcub1]" backward-char

# ctrl + left and right, jump over words
bindkey "^[[5C"            forward-word
bindkey "^[[1;5C"          forward-word
bindkey "^[[5D"            backward-word
bindkey "^[[1;5D"          backward-word

# home / end: begin and end string
bindkey "^[OF"              end-of-line
bindkey "^[[4~"             end-of-line
bindkey "${terminfo[kend]}" end-of-line
bindkey "^[OH"               beginning-of-line
bindkey "^[[1~"              beginning-of-line
bindkey "${terminfo[khome]}" beginning-of-line


# shift+tab: move through the completion menu backwards
if [[ "${terminfo[kcbt]}" != "" ]]; then
  bindkey "${terminfo[kcbt]}" reverse-menu-complete
fi

bindkey "^?"       backward-delete-char
if [[ "${terminfo[kdch1]}" != "" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char
else
  bindkey "^[[3~"  delete-char
  bindkey "^[3;5~" delete-char
  bindkey "\e[3~"  delete-char
fi
# bindkey "${terminfo[kbs]}"   delete-char

# pgup and pgdown: search history with same head
if [[ "${terminfo[kpp]}" != "" ]]; then
    bindkey "${terminfo[kpp]}" history-beginning-search-backward
else
    bindkey "\e[3D"            history-beginning-search-backward
    bindkey "\e[1;3D"          history-beginning-search-backward
    bindkey "\e\e[D"           history-beginning-search-backward
    bindkey "\eO3D"            history-beginning-search-backward
fi

if [[ "${terminfo[knp]}" != "" ]]; then
    bindkey "${terminfo[knp]}" history-beginning-search-forward
else
    bindkey "\e[3C"            history-beginning-search-forward
    bindkey "\e[1;3C"          history-beginning-search-forward
    bindkey "\e\e[C"           history-beginning-search-forward
    bindkey "\eO3C"            history-beginning-search-forward
fi

# up and down: search history substring
bindkey '^[[A'             history-substring-search-up
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey '^[[B'             history-substring-search-down
bindkey "$terminfo[kcud1]" history-substring-search-down

# bindkey "^[b" "^[f" # macos
bindkey "\e[3A"   insert-cycledleft
bindkey "\e[1;3A" insert-cycledleft
bindkey "\e\e[A"  insert-cycledleft
bindkey "\eO3A"   insert-cycledleft

bindkey "\e[3B"   insert-cycledright
bindkey "\e[1;3B" insert-cycledright
bindkey "\e\e[B"  insert-cycledright
bindkey "\eO3B"   insert-cycledright

bindkey "\e\e" clear-screen
bindkey '\e ' empty_buffer

bindkey '\e\' ps_widget
bindkey '^\' term_widget
bindkey '\e^\' kill_widget

bindkey "\e0"  commit_text
bindkey "\e-"  expand-cmd-path
bindkey "\e="  sudoize
bindkey "\e^?" autosuggest-execute # alt+backspace
bindkey "\e]"  copy-prev-shell-word

# bindkey "\ez" fuzzy-search-and-edit  # temporary disabled

bindkey '\ec'  history-search-multi-word
bindkey '\ex'  insert_endpoint
bindkey '\eX'  insert_directory
bindkey '\e^x' file_manager

bindkey "\ek" kill_last
fi
