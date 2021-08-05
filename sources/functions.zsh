LISTER_POST="${LISTER_FILE:-less} {} | ${LISTER_LESS} -R"
FORGIT_CMD_DIFF='git ls-files --modified `git rev-parse --show-toplevel`'
FZF_JUMPS='0123456789abcdefghijklmnopqrstuvwxyz'

commit_text () {
    local text=`sh -c "$HTTP_GET http://whatthecommit.com/index.txt"`
    echo "$text" | anyframe-action-insert
    zle end-of-line
}
zle -N commit_text


insert_directory() {
    if [ "$LBUFFER" ]; then
        local pre=`echo "$LBUFFER" | grep -Po '([^\s]+)$'`
    else
        local pre=""
    fi
    if [ "$RBUFFER" ]; then
        local post=`echo "$RBUFFER" | grep -Po '^([^\s]+)'`
    else
        local post=""
    fi

    if [ "$pre" ]; then
        if [ "$pre" = "$LBUFFER" ]; then
            LBUFFER=""
        else
            LBUFFER="$(echo ${LBUFFER% *} | sd '(\s+)$' '')"
        fi
    fi
    if [ "$post" ]; then
        if [ "$post" = "$RBUFFER" ]; then
            RBUFFER=""
        else
            RBUFFER="$(echo $RBUFFER | cut -d' ' -f2- | sd '^(\s+)' '')"
        fi
    fi

    local result=$(fd \
        --type directory \
        --follow \
        --one-file-system \
        --hidden \
        --exclude .git/ \
        --exclude "*.pyc" \
        --exclude node_modules/ \
        | fzf \
        --ansi --extended --info='inline' \
        --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
        --tiebreak=begin,length,end,index --jump-labels="$FZF_JUMPS" \
        --bind='alt-w:toggle-preview-wrap' \
        --bind='ctrl-c:abort' \
        --bind='ctrl-q:abort' \
        --bind='end:preview-down' \
        --bind='esc:abort' \
        --bind='home:preview-up' \
        --bind='pgdn:preview-page-down' \
        --bind='pgup:preview-page-up' \
        --bind='shift-down:half-page-down' \
        --bind='shift-up:half-page-up' \
        --bind='alt-space:jump' \
        --query="$pre$post" \
        --color="$FZF_THEME" \
        --reverse --min-height='11' --height='11' \
        --preview-window="right:119:noborder" \
        --prompt="catalog >  " \
        --preview="exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first {}" \
        -i -s --select-1 --filepath-word \
    )

    [ ! "$result" ] && local result="$pre$post"

    if [ "$LBUFFER" ]; then
        LBUFFER="$(echo $LBUFFER | sd '(\s+)$' '') $result"
    else
        LBUFFER="$result"
    fi
    if [ "$RBUFFER" ]; then
        RBUFFER=" $(echo $RBUFFER | sd '^(\s+)' '')"
    fi
    zle redisplay
}
zle -N insert_directory

insert_endpoint() {
    if [ "$LBUFFER" ]; then
        local pre=`echo "$LBUFFER" | grep -Po '([^\s]+)$'`
    else
        local pre=""
    fi
    if [ "$RBUFFER" ]; then
        local post=`echo "$RBUFFER" | grep -Po '^([^\s]+)'`
    else
        local post=""
    fi

    if [ "$pre" ]; then
        if [ "$pre" = "$LBUFFER" ]; then
            LBUFFER=""
        else
            LBUFFER="$(echo ${LBUFFER% *} | sd '(\s+)$' '')"
        fi
    fi
    if [ "$post" ]; then
        if [ "$post" = "$RBUFFER" ]; then
            RBUFFER=""
        else
            RBUFFER="$(echo $RBUFFER | cut -d' ' -f2- | sd '^(\s+)' '')"
        fi
    fi

    local result=$(fd \
        --type file \
        --type symlink \
        --type socket \
        --type pipe \
        --follow \
        --one-file-system \
        --hidden \
        --exclude .git/ \
        --exclude "*.pyc" \
        --exclude node_modules/ \
        | fzf \
        --ansi --extended --info='inline' \
        --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
        --tiebreak=begin,length,end,index --jump-labels="$FZF_JUMPS" \
        --bind='alt-w:toggle-preview-wrap' \
        --bind='ctrl-c:abort' \
        --bind='ctrl-q:abort' \
        --bind='end:preview-down' \
        --bind='esc:abort' \
        --bind='home:preview-up' \
        --bind='pgdn:preview-page-down' \
        --bind='pgup:preview-page-up' \
        --bind='shift-down:half-page-down' \
        --bind='shift-up:half-page-up' \
        --bind='alt-space:jump' \
        --query="$pre$post" \
        --color="$FZF_THEME" \
        --reverse --min-height='11' --height='11' \
        --preview-window="right:119:noborder" \
        --prompt="file >  " \
        --preview="exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first {}" \
        -i --select-1 --filepath-word \
    )

    [ ! "$result" ] && local result="$pre$post"

    if [ "$LBUFFER" ]; then
        LBUFFER="$(echo $LBUFFER | sd '(\s+)$' '') $result"
    else
        LBUFFER="$result"
    fi
    if [ "$RBUFFER" ]; then
        RBUFFER=" $(echo $RBUFFER | sd '^(\s+)' '')"
    fi
    zle redisplay
}
zle -N insert_endpoint

__fzf_use_tmux__() {
    [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
    __fzf_use_tmux__ &&
        echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

visual_chdir() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        [ -f "/tmp/.lastdir.tmp" ] && unlink /tmp/.lastdir.tmp
          # TODO: if file preview content
        local directory=$(fd \
            --type directory \
            --follow \
            --one-file-system \
            --hidden \
            --exclude .git/ \
            --exclude "*.pyc" \
            --exclude node_modules/ \
            --max-depth 3 \
            | sed '1i ..' | fzf \
                -i -s --exit-0 --select-1 \
                --prompt="chdir to: `pwd`/" \
                --bind='enter:accept' \
                --reverse --min-height='11' --height='11' \
                --preview-window="right:119:noborder" \
                --preview="exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first {}" \
                --filepath-word --tiebreak=begin,length,end,index \
                --bind='alt-bs:execute(echo `realpath {}` > /tmp/.lastdir.tmp)+abort' \
                --ansi --extended --info='inline' \
                --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
                --jump-labels="$FZF_JUMPS" \
                --bind='alt-space:jump-accept' \
                --bind='alt-w:toggle-preview-wrap' \
                --bind='ctrl-c:abort' \
                --bind='ctrl-q:abort' \
                --bind='end:preview-down' \
                --bind='esc:cancel' \
                --bind='home:preview-up' \
                --bind='pgdn:preview-page-down' \
                --bind='pgup:preview-page-up' \
                --bind='shift-down:half-page-down' \
                --bind='shift-up:half-page-up' \
                --color="$FZF_THEME" \
        )

        if [ -f "/tmp/.lastdir.tmp" ]; then
            builtin cd `cat /tmp/.lastdir.tmp` &> /dev/null
            unlink /tmp/.lastdir.tmp
            l --git-ignore
            zle reset-prompt
            return 0
        fi

        if [ "$directory" = ".." ]; then
            builtin cd .. &> /dev/null

        elif [ "$directory" ]; then
            builtin cd "$directory" &> /dev/null
            if [ "`fd --type directory | wc -l`" -gt 0 ]; then
            else
                l --git-ignore
                zle reset-prompt
                return 0
            fi

        else
            l --git-ignore
            zle reset-prompt
            return 0
        fi
    done
}
zle -N visual_chdir


visual_recent_chdir() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    local directory=$(scotty list | sort -rk 2,3 | sed '1d' | tabulate -i 1 | runiq - | \
        fzf \
            -i -s --exit-0 --select-1 \
            --prompt="chdir >  " \
            --bind='enter:accept' \
            --reverse --min-height='11' --height='11' \
            --preview-window="right:119:noborder" \
            --preview="exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first {}" \
            --filepath-word --tiebreak=index \
            --ansi --extended --info='inline' \
            --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
            --jump-labels="$FZF_JUMPS" \
            --bind='alt-space:jump-accept' \
            --bind='alt-w:toggle-preview-wrap' \
            --bind='ctrl-c:abort' \
            --bind='ctrl-q:abort' \
            --bind='end:preview-down' \
            --bind='esc:cancel' \
            --bind='home:preview-up' \
            --bind='pgdn:preview-page-down' \
            --bind='pgup:preview-page-up' \
            --bind='shift-down:half-page-down' \
            --bind='shift-up:half-page-up' \
            --color="$FZF_THEME" \
    )

    if [ "$directory" ]; then
        builtin cd "$directory" &> /dev/null
    fi
    zle reset-prompt
    return 0

}
zle -N visual_recent_chdir


insert_command() {
    local query="`echo "$BUFFER" | grep -Po '([^\s]+)$'`"
    local query="`echo "$BUFFER" | grep -Po '^([^\s]+)'`"
    local query="`echo "$BUFFER" | sd '(\s+)' ' '`"

    local result=$(cat $HISTFILE | grep -PIs '^(: \d+:\d+;)' | sd ': \d+:\d+;' '' | grep -Pv '^\s+' | runiq - | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | sed 1d | fzf \
        --ansi --extended --info='inline' \
        --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
        --tiebreak=index --jump-labels="$FZF_JUMPS" \
        --bind='alt-w:toggle-preview-wrap' \
        --bind='ctrl-c:abort' \
        --bind='ctrl-q:abort' \
        --bind='end:preview-down' \
        --bind='esc:abort' \
        --bind='home:preview-up' \
        --bind='pgdn:preview-page-down' \
        --bind='pgup:preview-page-up' \
        --bind='shift-down:half-page-down' \
        --bind='shift-up:half-page-up' \
        --bind='alt-space:jump' \
        --query="$query" \
        --color="$FZF_THEME" \
        --reverse --min-height='11' --height='11' \
        --prompt="command >  " \
        -i --select-1 --filepath-word \
    )

    if [ "$result" ]; then
        BUFFER="$result"
    fi
    zle redisplay
    return 0
}
zle -N insert_command


chdir_up() {
    builtin cd "`realpath ..`"
    zle reset-prompt
    return 0
}
zle -N chdir_up

chdir_home() {
    builtin cd "`realpath ~`"
    zle reset-prompt
    return 0
}
zle -N chdir_home


visual_grep() {
    local ripgrep="`which -p rg` --max-filesize=50K --hidden --fixed-strings --ignore-file=`realpath ~/.ignore` --ignore-file=`realpath $JOSH/configs/grep.ignore` --smart-case"
    local execute="$JOSH/sources/functions/scripts/rg_query_name_to_micro.sh"
    local preview="echo {}:{q} | grep -Pv '^:' | sed -r 's#(.+?):[0-9]+:(.+?)#>>\2<<//\1#g' | sd '>>(\s*)(.*?)(\s*)<<//(.+)' '$ripgrep  --vimgrep --context 0 \"\$2\" \$4' | $SHELL | tabulate -d ':' -i 2 | huniq | sort -V | sed 's/^/-H/' | tr '\n' ' ' | xargs -I% echo % {} | tabulate -d ':' -i 1 | xargs -I% sh -c 'bat --color=always --terminal-width $COLUMNS %'"

    local file=$(
        fzf \
        --bind "change:reload:($ripgrep --count --color=always -- {q} | proximity-sort . || true)" \
        --bind="enter:execute(echo "{q}:{}" | $SHELL $execute | xargs -I$ sh -c '$')" \
        --prompt='grep: ' --query='' --tiebreak='index' \
        --disabled --preview-window='left:104:noborder' \
        --preview="$preview" \
        --ansi --extended --info='inline' \
        --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
        --jump-labels="$FZF_JUMPS" \
        --bind='alt-space:jump-accept' \
        --bind='alt-w:toggle-preview-wrap' \
        --bind='ctrl-c:abort' \
        --bind='ctrl-q:abort' \
        --bind='end:preview-down' \
        --bind='esc:cancel' \
        --bind='home:preview-up' \
        --bind='pgdn:preview-page-down' \
        --bind='pgup:preview-page-up' \
        --bind='shift-down:half-page-down' \
        --bind='shift-up:half-page-up' \
        --color="$FZF_THEME" \
    )
    zle reset-prompt
    return 0
}
zle -N visual_grep

ps_widget() {
    while true; do
        local pids="$(
            ps -o %cpu,%mem,pid,command -A | grep -v "zsh" | awk '{$1=$1};1' | \
            awk 'NR<2{print $0;next}{print $0| "sort -rk 1,2"}' | \
            tr -s ' ' | sed 's/ /\t/g' | sed 's/\t/ /g4' | \
            fzf --color="$FZF_THEME" \
                --prompt="just paste:" \
                --multi --info='inline' --ansi --extended \
                --filepath-word --no-mouse --tiebreak=length,index \
                --pointer=">" --marker="+" --margin=0,0,0,0 \
                --reverse --header-lines=1 --nth 4.. --height 40% \
            | cut -f 3 | sed -z 's/\n/ /g' | awk '{$1=$1};1'
        )"
        if [[ "$pids" != "" ]]; then
            if [ "$LBUFFER" ]; then
                LBUFFER="$LBUFFER $pids"
                if [ "$RBUFFER" ]; then
                    RBUFFER=" $RBUFFER"
                fi
            else
                LBUFFER="$pids"
                if [ "$RBUFFER" ]; then
                    RBUFFER=" $RBUFFER"
                fi
            fi
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
            --prompt="terminate:" --color="$FZF_THEME" \
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
            --prompt="kill!" --color="$FZF_THEME" \
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
    bat $tmpfile
    rm -f $tmpfile
}

term_last() {
    kill %1
}
zle -N term_last

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

    . "$JOSH/install/units/rust.sh"
    deploy_packages $REQUIRED_PACKAGES
    exec zsh
    return 0
}

josh_deploy() {
    url="https://raw.githubusercontent.com/YaakovTooth/Josh/master/install/boot.sh?$RANDOM"
    $SHELL -c "$HTTP_GET $url | $SHELL"
    if [ $? -gt 0 ]; then
        echo ' - install failed :-\'
        return 1
    fi
}

josh_urls() {
    echo '  (curl -fsSL kalaverin.ru/shell | $SHELL) && zsh'
    echo '  (wget -qO - kalaverin.ru/shell | $SHELL) && zsh'
    echo ' (fetch -qo - kalaverin.ru/shell | $SHELL) && zsh'
}

josh_extras() {
    . "$JOSH/install/units/rust.sh"
    deploy_extras
}

find /tmp -maxdepth 1 -name "fuzzy-search-and-edit.*" -user $USER -type d -mmin +30 -exec rm -rf {} \;
