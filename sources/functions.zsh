LISTER_POST="${LISTER_FILE:-less} {} | ${LISTER_LESS} -R"
FORGIT_CMD_DIFF='git ls-files --modified `git rev-parse --show-toplevel`'


commit_text () {
    local text=`sh -c "$READ_URI http://whatthecommit.com/index.txt"`
    echo "$text" | anyframe-action-insert
    zle end-of-line
}
zle -N commit_text

insert_locate() {
    # #@todo --history
    local selected
    if selected=$(locate / | fzf -1 --ansi --bind='ctrl-r:toggle-all' --bind='ctrl-s:toggle-sort' --bind 'esc:cancel' --query="$BUFFER" --preview '
        __cd_nxt="$(echo {})";
        __cd_path="$(echo ${__cd_nxt} | sed "s;//;/;")";
        echo $__cd_path;
        echo;
        ls -la "${__cd_path}";
    '); then
        RBUFFER=$selected
    fi
    zle redisplay
}
zle -N insert_locate

__select_any_path() {
    local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
        -o -type f -print \
        -o -type d -print \
        -o -type l -print 2> /dev/null | cut -b3-"}"
    setopt localoptions pipefail 2> /dev/null
    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
    done
    local ret=$?
    echo
    return $ret
}

__fzf_use_tmux__() {
    [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
    __fzf_use_tmux__ &&
        echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

insert_path() {
    result=`echo "$(__select_any_path)"`
    LBUFFER="${LBUFFER}$result"
    local ret=$?
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}
zle -N insert_path

file_manager() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -A -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --bind 'esc:cancel' --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls "${__cd_path}";
        ')"
        if [[ ${#dir} != 0 ]]; then
            builtin cd "$dir" &> /dev/null
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N file_manager

ps_widget() {
    while true; do
        local pids="$(
            ps -o %cpu,%mem,pid,command -A | grep -v "zsh" | awk '{$1=$1};1' | \
            awk 'NR<2{print $0;next}{print $0| "sort -rk 1,2"}' | \
            tr -s ' ' | sed 's/ /\t/g' | sed 's/\t/ /g4' | \
            fzf \
                --prompt="select:" \
                --multi --info='inline' --ansi --extended \
                --filepath-word --no-mouse --tiebreak=length,index \
                --pointer=">" --marker="+" --margin=0,0,0,0 \
                --reverse --header-lines=1 --nth 4.. --height 40% \
            | cut -f 3 | sed -z 's/\n/ /g' | awk '{$1=$1};1'
        )"
        if [[ "$pids" != "" ]]; then
            LBUFFER="${LBUFFER}$pids"
            local ret=$?
            zle redisplay
            typeset -f zle-line-init >/dev/null && zle zle-line-init
            return $ret
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N ps_widget


term_widget() {
    local pids="$(
        ps -o %cpu,%mem,pid,command -A | grep -v "zsh" | awk '{$1=$1};1' | \
        awk 'NR<2{print $0;next}{print $0| "sort -rk 1,2"}' | \
        tr -s ' ' | sed 's/ /\t/g' | sed 's/\t/ /g4' | \
        fzf \
            --prompt="term:" \
            --multi --info='inline' --ansi --extended \
            --filepath-word --no-mouse --tiebreak=length,index \
            --pointer=">" --marker="+" --margin=0,0,0,0 \
            --reverse --header-lines=1 --nth 4.. --height 40% \
        | cut -f 3 | sed -z 's/\n/ /g' | awk '{$1=$1};1'
    )"
    while true; do
        if [[ "$pids" != "" ]]; then
            sh -c "kill -15 $pids"
            return 0
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N term_widget

kill_widget() {
    local pids="$(
        ps -o %cpu,%mem,pid,command -A | grep -v "zsh" | awk '{$1=$1};1' | \
        awk 'NR<2{print $0;next}{print $0| "sort -rk 1,2"}' | \
        tr -s ' ' | sed 's/ /\t/g' | sed 's/\t/ /g4' | \
        fzf +x \
            --prompt="kill:" \
            --multi --info='inline' --ansi --extended \
            --filepath-word --no-mouse --tiebreak=length,index \
            --pointer=">" --marker="+" --margin=0,0,0,0 \
            --reverse --header-lines=1 --nth 4.. --height 40% \
        | cut -f 3 | sed -z 's/\n/ /g' | awk '{$1=$1};1'
    )"
    while true; do
        if [[ "$pids" != "" ]]; then
            sh -c "kill -9 $pids"
            return 0
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N kill_widget

autoload znt-history-widget
zle -N znt-history-widget

autoload znt-kill-widget
zle -N znt-kill-widget

autoload -U edit-command-line
zle -N edit-command-line

share_file() {
    if [ $# -eq 0 ]
        then echo -e "No arguments specified. Usage:\necho share /tmp/test.md\ncat /tmp/test.md | share test.md"
        return 1
    fi
    tmpfile=$( mktemp -t transferXXX )
    if tty -s
        then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g')
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile
    else
        curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile
    fi
    cat $tmpfile
    rm -f $tmpfile
}

kill_last() {
    kill %1
}
zle -N kill_last

empty_buffer() {
    if [[ ! -z $BUFFER ]]; then
        LBUFFER=''
        RBUFFER=''
        zle redisplay
    fi
}
zle -N empty_buffer

sudoize() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudoize

josh_pull() {
    cmd="git --work-tree=$JOSH --git-dir=$JOSH/.git"
    $SHELL -c "$cmd checkout master && $cmd pull"
    if [ $? -gt 0 ]; then
        echo ' - update failed :-\'
        return 1
    fi
    return 0
}

josh_deploy() {
    url="https://raw.githubusercontent.com/YaakovTooth/Josh/master/install/boot.sh?$RANDOM"
    $SHELL -c "$READ_URI $url | $SHELL"
    if [ $? -gt 0 ]; then
        echo ' - install failed :-\'
        return 1
    fi
}

josh_urls() {
    echo ' For install with sudo rights just run:'
    echo '  (curl -fsSL https://goo.gl/NCF9so | sh) && exec zsh'
    echo '  (wget -qO - https://goo.gl/NCF9so | sh) && exec zsh'
    echo ' (fetch -qo - https://goo.gl/NCF9so | sh) && exec zsh'
    echo ''
    echo ' For install under user run:'
    echo '  (curl -fsSL https://goo.gl/1MBc9t | sh) && exec zsh'
    echo '  (wget -qO - https://goo.gl/1MBc9t | sh) && exec zsh'
    echo ' (fetch -qo - https://goo.gl/1MBc9t | sh) && exec zsh'
}

josh_deploy_extras() {
    . "$JOSH/install/units/rust.sh"
    deploy_extras
}

# autosuggestions and safe-paste patch
# function _start_paste() {
#     _zsh_autosuggest_widget_clear
#     bindkey -A paste main
# }
# function _end_paste() {
#     _zsh_autosuggest_widget_disable
#     bindkey -e
#     LBUFFER+=$_paste_content
#     unset _paste_content
#     _zsh_autosuggest_widget_enable
# }
# 
# function upgrade_custom() {
#     (_upgrade_custom)
# }

# find /tmp -maxdepth 1 -name "fuzzy-search-and-edit.*" -user $USER -type d -mmin +30 -exec rm -rf {} \;
