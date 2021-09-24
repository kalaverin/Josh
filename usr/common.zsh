. $JOSH/lib/shared.sh

# ———

local THIS_DIR=`dirname "$($JOSH_READLINK -f "$0")"`
local INCLUDE_DIR="`realpath $THIS_DIR/src`"


commit_text () {
    local text=`sh -c "$HTTP_GET http://whatthecommit.com/index.txt"`
    echo "$text" | anyframe-action-insert
    zle end-of-line
}
zle -N commit_text

insert_directory() {
    # анализировать запрос и если есть слеш и такой каталог — то есть уже в нём
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
        --hidden \
        --one-file-system \
        --ignore-file ~/.gitignore \
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
        --preview-window="right:`get_preview_width`:noborder" \
        --prompt="dir >  " \
        --preview="$SHELL $JOSH/usr/src/viewer.sh {}" \
        -i --filepath-word \
    )

    [ ! "$result" ] && local result="$pre$post"

    if [ "$LBUFFER" ]; then
        LBUFFER="$(echo $LBUFFER | sd '(\s+)$' '') $result"
    else
        LBUFFER=" $result"
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
        --type pipe \
        --type socket \
        --type symlink \
        --follow \
        --hidden \
        --ignore-file ~/.gitignore \
        --one-file-system \
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
        --preview-window="right:`get_preview_width`:noborder" \
        --prompt="file >  " \
        --preview="$SHELL $JOSH/usr/src/viewer.sh {}" \
        -i --filepath-word \
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

visual_chdir() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local cwd="`pwd`"
        local temp="`get_tempdir`"
        local name="`basename $cwd`"

        [ -f "/$temp/.lastdir.tmp" ] && unlink "$temp/.lastdir.tmp"
          # TODO: if file preview content
        local directory=$(fd \
            --type directory \
            --follow \
            --hidden \
            --ignore-file ~/.gitignore \
            --one-file-system \
            --max-depth 5 . '../' \
            | sd "^(../$name)/" '' | grep -Pv "^(../$name)$" \
            | runiq - | proximity-sort . | sed '1i ..' |sed '1i .' | fzf \
                -i \
                --prompt="`pwd`/" \
                --bind='enter:accept' \
                --reverse --min-height='11' --height='11' \
                --preview-window="right:`get_preview_width`:noborder" \
                --preview="$SHELL $JOSH/usr/src/viewer.sh {}" \
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

        if [ -f "$temp/.lastdir.tmp" ]; then
            builtin cd `cat $temp/.lastdir.tmp` &> /dev/null
            unlink "$temp/.lastdir.tmp"
            pwd; l --git-ignore
            zle reset-prompt
            return 0
        fi

        if [ "$directory" ]; then
            builtin cd "$directory" &> /dev/null

        else
            pwd; l --git-ignore
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

    local directory=$(scotty list | sed '1d' | sort -rk 2,3 | sd '(.+?)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2}\.\d+)$' '$2-$3 $1' | sort -rk 1 | tabulate -i 2 | runiq - | xargs -I$ echo "[ -d \"$\" ] && echo \"$\"" | $SHELL | grep -Pv 'env/.+/bin' | \
        fzf \
            -i -s --exit-0 --select-1 \
            --prompt="cd >  " \
            --bind='enter:accept' \
            --reverse --min-height='11' --height='11' \
            --preview-window="right:`get_preview_width`:noborder" \
            --preview='exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first '{}'' \
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


visual_warp_chdir() {
    local directory=$(wd list | sd '(.+?)\s+->\s+(.+)' '$1::$2' | sed '1d' | sort -k 1 | sd '::(~)' "::$HOME" | tabulate -d '::' | \
        fzf \
            -i -s --exit-0 --select-1 \
            --prompt="wd >  " \
            --bind='enter:accept' \
            --reverse --min-height='11' --height='11' \
            --preview-window="right:`get_preview_width`:noborder" \
            --preview='exa -lFag --color=always --git --git-ignore --octal-permissions --group-directories-first '{2}'' \
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
        | tabulate -i 1
    )

    if [ "$directory" ]; then
        wd "$directory"
    fi
    zle reset-prompt
    return 0
}
zle -N visual_warp_chdir


insert_command() {
    local query="`echo "$BUFFER" | sd '(\s+)' ' ' | sd '(^\s+|\s+$)' ''`"
    local result="$(cat $HISTFILE | grep -PIs '^(: \d+:\d+;)' | sd ': \d+:\d+;' '' | grep -Pv '^\s+' | runiq - | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | sed 1d | fzf \
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
        --bind='alt-space:jump-accept' \
        --query="$query" \
        --color="$FZF_THEME" \
        --reverse --min-height='11' --height='11' \
        --prompt="run >  " \
        -i --select-1 --filepath-word \
    )"

    if [ "$result" ]; then
        LBUFFER="$result"
        RBUFFER=""
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
    local execute="$INCLUDE_DIR/ripgrep_query_name_to_micro.sh"
    local search_one="$JOSH/usr/src/ripgrep_spaced_words.sh"

    local query=""
    while true; do
        local ripgrep="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS --smart-case"
        local preview="echo {2} | $JOSH_GREP -Pv '^:' | sd '(^\d+|(?::)\d+)' ' -H\$1' | sd ':' '' | sd '(^\s+|\s+$)' '' | sd '^-H(\d+)' ' -r\$1: -H\$1 ' | sd '(.)$' '\$1 {1}' | xargs bat --terminal-width \$FZF_PREVIEW_COLUMNS --color=always"

        local query=$(
            echo "$query" | $SHELL $search_one \
            | fzf \
            --prompt='query search >  ' --query="$query" --tiebreak='index' \
            --no-sort \
            --disabled \
            --nth=2.. --with-nth=1.. \
            --bind "change:reload:(echo \"{q}\" | $SHELL $search_one || true)" \
            --preview-window="left:`get_preview_width`:noborder" \
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
            --print-query | head -n 1
        )
        [ ! "$query" ] && break
        return 0


        while true; do
            local ripgrep="$JOSH_RIPGREP $JOSH_RIPGREP_OPTS --smart-case --word-regexp"
            local preview="echo {2}:$query | $JOSH_GREP -Pv '^:' | $JOSH_SED -r 's#(.+?):(.+?)#>>\2<<//\1#g' | sd '>>(\s*)(.*?)(\s*)<<//(.+)' '$ripgrep --vimgrep --context 0 \"\$2\" \$4' | $SHELL | tabulate -d ':' -i 2 | runiq - | sort -V | tr '\n' ' ' | sd '^([^\s]+)(.*)$' ' -r\$1: \$1\$2' | sd '(\s+)(\d+)' ' -H\$2' | xargs -I@ echo 'bat --terminal-width \$FZF_PREVIEW_COLUMNS --color=always @ {2}' | $SHELL"

            # $SHELL -c "$ripgrep --color=always --count -- \"$query\" | sd '^(.+):(\d+)$' '\$2 \$1' | sort -grk 1" \
            local value=$(
                $SHELL -c "echo \"{q}\" | sd '([^\w\d]+)' ' ' | sd '(^ | $)' '' | sd ' +' '.+' | xargs -n 1 $ripgrep --with-filename --line-number --heading -- | sd '\n^(\d:).+$' ':\$1' | sd ':+' ':' | sd ':$' '' | sd '\n+' '\n' | sd ':([\d:]+)$' ' \$1' | sort -grk 1" \
                | fzf \
                --prompt="query \`$query\` >  " --query='' --tiebreak='index' \
                --no-sort \
                --nth=2.. --with-nth=1.. \
                --preview-window="left:`get_preview_width`:noborder" \
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
                --color="$FZF_THEME" | sd '^(\d+\s+)' '' \
            )
            [ ! "$value" ] && break
            micro $value $($SHELL -c "$JOSH_RIPGREP --smart-case --fixed-strings --no-heading --column --with-filename --max-count=1 --color=never \"$query\" \"$value\" | tabulate -d ':' -i 1,2,3 | sd '(.+?)\s+(\d+)\s+(\d+)' '+\$2:\$3'")
        done
    done

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

share_file() {
    if [ $# -eq 0 ]
        local temp="`get_tempdir`"
        then echo -e "No arguments specified. Usage:\necho share $temp/test.md\ncat $temp/test.md | share test.md"
        return 1
    fi
    tmpfile=$(mktemp -t transferXXX)
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

josh_update() {
    local cwd="`pwd`"
    josh_pull $@ && \
    source "$JOSH/run/update.sh" && post_update $@
    local retval="$?"
    builtin cd "$cwd"
    exec zsh
    return $retval
}

josh_pull() {
    local cwd="`pwd`"
    source "$JOSH/run/update.sh" && pull_update $@
    local retval="$?"
    builtin cd "$cwd"
    return $retval
}

josh_reinstall() {
    local cwd="`pwd`"
    url='"https://kalaverin.ru/shell?$RANDOM"'
    run_show "$HTTP_GET $url | $SHELL"
    local retval="$?"
    if [ "$retval" -gt 0 ]; then
        echo ' - fatal: something wrong :-\'
        return 1
    fi
    builtin cd "$cwd"
    exec zsh
    return $retval
}

josh_bootstrap_command() {
    local url="${1:-"http://kalaverin.ru/shell}"}"
    echo "((curl -fsSL $url || wget -qO - $url || fetch -qo - $url) | zsh) && zsh"
}

josh_branch() {
    echo "$(
        git --git-dir="$JOSH/.git" --work-tree="$JOSH/" \
        rev-parse --quiet --abbrev-ref HEAD 2>/dev/null
    )"
}

josh_bootstrap_command_branched() {
    if [ -n "$1" ]; then
        local branch="$1"

    else
        local branch="`josh_branch`"
    fi

    local url="https://raw.githubusercontent.com/YaakovTooth/Josh/$branch/run/boot.sh"
    echo "export JOSH_RENEW_CONFIGS=1 && export JOSH_BRANCH="$branch" && ((curl -fsSL $url || wget -qO - $url || fetch -qo - $url) | zsh); unset JOSH_RENEW_CONFIGS && unset JOSH_BRANCH"
}

josh_extras() {
    source "$JOSH/run/update.sh"
    deploy_extras
}

autoload znt-history-widget
zle -N znt-history-widget

autoload znt-kill-widget
zle -N znt-kill-widget

autoload -U edit-command-line
zle -N edit-command-line

find /tmp -maxdepth 1 -name "fuzzy-search-and-edit.*" -user $USER -type d -mmin +30 -exec rm -rf {} \;
