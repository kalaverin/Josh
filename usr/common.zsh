local THIS_DIR="$(fs.realdir "$0")"
local INCLUDE_DIR="$(fs.realpath $THIS_DIR/src)"

function clear {
    local bin="$commands[clear]"
    if [ -x "$bin" ]; then
        $bin
    fi
    let lines="$LINES - 2"
    for i in {1..$lines}
    do
        printf "\n"
    done
}

function cls {
    clear
    if [ -z "$ASH_TMUX_MOTD_DISABLE" ]; then
        if [ -x "$commands[krabby]" ]; then
            krabby random | sed 1d | head -n -1
        fi
        if [ -x "$commands[dsmsg]" ]; then
            let color="31 + ($RANDOM % 7)"
            printf "\033[2;${color}m -- $(dsmsg --ds1 --ds2 --ds3)\033[0m\n"
        fi
    fi
}

function commit_text {
    local text="`$SHELL -c "$HTTP_GET http://whatthecommit.com/index.txt"`"
    echo "$text" | anyframe-action-insert
    zle end-of-line
}
zle -N commit_text

function insert_directory {
    # анализировать запрос и если есть слеш и такой каталог — то есть уже в нём
    if [ "$LBUFFER" ]; then
        local pre="`echo "$LBUFFER" | grep -Po '([^\s]+)$'`"
    else
        local pre=""
    fi
    if [ "$RBUFFER" ]; then
        local post="`echo "$RBUFFER" | grep -Po '^([^\s]+)'`"
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
        --preview-window="right:`misc.preview.width`:noborder" \
        --prompt="dir >  " \
        --preview="$SHELL $ASH/usr/src/viewer.sh {}" \
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

function insert_endpoint {
    if [ "$LBUFFER" ]; then
        local pre="`echo "$LBUFFER" | grep -Po '([^\s]+)$'`"
    else
        local pre=""
    fi
    if [ "$RBUFFER" ]; then
        local post="`echo "$RBUFFER" | grep -Po '^([^\s]+)'`"
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
        --preview-window="right:`misc.preview.width`:noborder" \
        --prompt="file >  " \
        --preview="$SHELL $ASH/usr/src/viewer.sh {}" \
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

function visual_chdir {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local cwd="`pwd`"
        local temp="`temp.dir`"
        local name="`fs.basename $cwd`"

        [ -f "$temp/.lastdir.tmp" ] && unlink "$temp/.lastdir.tmp"

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
                --preview-window="right:`misc.preview.width`:noborder" \
                --preview="$SHELL $ASH/usr/src/viewer.sh {}" \
                --filepath-word --tiebreak=begin,length,end,index \
                --bind="alt-bs:execute(echo \`realpath {}\` > $temp/.lastdir.tmp)+abort" \
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
            pwd; l
            zle reset-prompt
            return 0
        fi

        if [ "$directory" ]; then
            builtin cd "$directory" &> /dev/null

        else
            pwd; l
            zle reset-prompt
            return 0
        fi
    done
}
zle -N visual_chdir

function visual_recent_chdir {
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
            --preview-window="right:`misc.preview.width`:noborder" \
            --preview="$SHELL $ASH/usr/src/viewer.sh {}" \
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

function visual_warp_chdir {
    local directory=$(wd list | sd '(.+?)\s+->\s+(.+)' '$1::$2' | sed '1d' | sort -k 1 | sd '::(~)' "::$HOME" | tabulate -d '::' | \
        fzf \
            -i -s --exit-0 --select-1 \
            --prompt="wd >  " \
            --bind='enter:accept' \
            --reverse --min-height='11' --height='11' \
            --preview-window="right:`misc.preview.width`:noborder" \
            --preview="$SHELL $ASH/usr/src/viewer.sh {2}" \
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

function insert_command {
    local file="`temp.dir`/.insert.cmd.tmp"
    [ -f "$file" ] && unlink "$file"

    local query="`echo "$BUFFER" | sd '(\s+)' ' ' | sd '(^\s+|\s+$)' ''`"
    local result="$(
        grep -PIs '^(: \d+:\d+;)' "$HISTFILE" \
        | sd ': \d+:\d+;' '' | grep -Pv '^\s+' | runiq - \
        | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' \
        | sed 1d | fzf \
        --ansi --extended --info='inline' \
        --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' \
        --tiebreak=index --jump-labels="$FZF_JUMPS" \
        --bind='alt-w:toggle-preview-wrap' \
        --bind="ctrl-q:execute(echo "{q}" > "$file")+abort" \
        --bind='ctrl-c:abort' \
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

    [ -z "$result" ] && echo 1
    [ -f "$file" ] && echo 2

    if [ -z "$result" ] && [ -f "$file" ]; then
        local result="`cat $file`"; unlink "$file"
    fi

    if [ -n "$result" ]; then
        LBUFFER="$result"
        RBUFFER=""
    fi

    zle redisplay
    return 0
}
zle -N insert_command

function chdir_up {
    builtin cd "`fs.realpath ..`"
    zle reset-prompt
    return 0
}
zle -N chdir_up

function chdir_home {
    builtin cd "`fs.realpath ~`"
    zle reset-prompt
    return 0
}
zle -N chdir_home

function visual_grep {
    local execute="$INCLUDE_DIR/ripgrep_query_name_to_micro.sh"
    local search_one="$ASH/usr/src/ripgrep_spaced_words.sh"

    local query=""
    while true; do
        local ripgrep="$ASH_RIPGREP $ASH_RIPGREP_OPTS --smart-case"
        local preview="echo {2} | grep -Pv '^:' | sd '(^\d+|(?::)\d+)' ' -H\$1' | sd ':' '' | sd '(^\s+|\s+$)' '' | sd '^-H(\d+)' ' -r\$1: -H\$1 ' | sd '(.)$' '\$1 {1}' | xargs bat --terminal-width \$FZF_PREVIEW_COLUMNS --color=always"

        local query=$(
            echo "$query" | $SHELL $search_one \
            | fzf \
            --prompt='query search >  ' --query="$query" --tiebreak='index' \
            --no-sort \
            --disabled \
            --nth=2.. --with-nth=1.. \
            --bind "change:reload:(echo \"{q}\" | $SHELL $search_one || true)" \
            --preview-window="left:`misc.preview.width`:noborder" \
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
            local ripgrep="$ASH_RIPGREP $ASH_RIPGREP_OPTS --smart-case --word-regexp"
            local preview="echo {2}:$query | grep -Pv '^:' | sed -r 's#(.+?):(.+?)#>>\2<<//\1#g' | sd '>>(\s*)(.*?)(\s*)<<//(.+)' '$ripgrep --vimgrep --context 0 \"\$2\" \$4' | $SHELL | tabulate -d ':' -i 2 | runiq - | sort -V | tr '\n' ' ' | sd '^([^\s]+)(.*)$' ' -r\$1: \$1\$2' | sd '(\s+)(\d+)' ' -H\$2' | xargs -I@ echo 'bat --terminal-width \$FZF_PREVIEW_COLUMNS --color=always @ {2}' | $SHELL"

            # $SHELL -c "$ripgrep --color=always --count -- \"$query\" | sd '^(.+):(\d+)$' '\$2 \$1' | sort -grk 1" \
            local value=$(
                $SHELL -c "echo \"{q}\" | sd '([^\w\d]+)' ' ' | sd '(^ | $)' '' | sd ' +' '.+' | xargs -n 1 $ripgrep --with-filename --line-number --heading -- | sd '\n^(\d:).+$' ':\$1' | sd ':+' ':' | sd ':$' '' | sd '\n+' '\n' | sd ':([\d:]+)$' ' \$1' | sort -grk 1" \
                | fzf \
                --prompt="query \`$query\` >  " --query='' --tiebreak='index' \
                --no-sort \
                --nth=2.. --with-nth=1.. \
                --preview-window="left:`misc.preview.width`:noborder" \
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
            micro $value $($SHELL -c "$ASH_RIPGREP --smart-case --fixed-strings --no-heading --column --with-filename --max-count=1 --color=never \"$query\" \"$value\" | tabulate -d ':' -i 1,2,3 | sd '(.+?)\s+(\d+)\s+(\d+)' '+\$2:\$3'")
        done
    done

    zle reset-prompt
    return 0
}
zle -N visual_grep

function ps_widget {
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

function term_widget {
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
            run.show "kill -15 $pids"
            echo ""
            zle redisplay
            return "$?"
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N term_widget

function kill_widget {
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
            run.show "kill -9 $pids"
            echo ""
            zle redisplay
            return "$?"
        else
            zle reset-prompt
            return 0
        fi
    done
}
zle -N kill_widget

function share_file {
    if [ $# -eq 0 ]
        local temp="`temp.dir`"
        then echo -e "No arguments specified. Usage:\necho share $temp/test.md\ncat $temp/test.md | share test.md"
        return 1
    fi
    tmpfile=$(mktemp -t transferXXX)
    if tty -s
        then basefile=$(fs.basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g')
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile
    else
        curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile
    fi
    bat $tmpfile
    rm -f $tmpfile
}

function term_last {
    kill %1
}
zle -N term_last

function empty_buffer {
    if [[ ! -z $BUFFER ]]; then
        LBUFFER=''
        RBUFFER=''
        zle redisplay
    fi
}
zle -N empty_buffer

function sudoize {
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


function __ash.branch {
    echo "$(
        git --git-dir="$ASH/.git" --work-tree="$ASH/" \
        rev-parse --quiet --abbrev-ref HEAD 2>/dev/null
    )"
}
function ash.branch {
    if [ -n "$ASH" ] && [ -d "$ASH" ]; then
        local branch="$(__ash.branch)"
        if [ "$?" -eq 0 ]; then
            echo "$branch"
            return 0
        fi
    fi
    return 1
}
function __ash.update.pre {
    local cwd="$PWD"
    py.set || return "$?"
    echo "$cwd"
}
function ash.pull {
    local version; version="$(py.ver)" || return "$?"
    export ASH_POST_INSTALL_PYTHON="$version"

    local cwd; cwd="$(__ash.update.pre)" || return "$?"
    ash.eval "run/update.sh" && pull.update $* && \
    ash.eval "run/update.sh" && post.install
    builtin cd "$cwd"

    local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}"
    [[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
}
function ash.update {
    local version; version="$(py.ver)" || return "$?"
    export ASH_POST_INSTALL_PYTHON="$version"

    local cwd; cwd="$(__ash.update.pre)" || return "$?"
    ash.eval "run/update.sh" && pull.update $* && \
    ash.eval "run/update.sh" && post.update $*
    builtin cd "$cwd"

    local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}"
    [[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
}
function ash.upgrade {
    local version; version="$(py.ver)" || return "$?"
    export ASH_POST_INSTALL_PYTHON="$version"

    local cwd; cwd="$(__ash.update.pre)" || return "$?"
    ash.eval "run/update.sh" && pull.update $* && \
    ash.eval "run/update.sh" && post.upgrade $*
    builtin cd "$cwd"

    local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}"
    [[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
}
function ash.extras {
    ash.eval "run/update.sh" && deploy.extras
}

function ash.cache.drop {
    rm -rf "$HOME/.cache/josh/"
}

function ash.eval {
    if [ -z "$1" ]; then
        return 1

    elif [ -z "$2" ]; then
        if [ -e "$ASH/$1" ]; then
            source "$ASH/$1"
            return "$?"
        else
            return 127
        fi
    fi

    local result=''
    for file in $*; do
        if [ ! -f "$ASH/$file" ]; then
            if [ -z "$result" ]; then
                local result="$file"
            else
                local result="$result $file"
            fi
        fi
    done

    if [ -n "$result" ]; then
        fail $0 "doesn't exists: $result"
        return 2
    fi

    for file in $*; do
        source "$ASH/$file"
    done
}


ASH_DEPRECATIONS[josh_branch]=ash.branch
ASH_DEPRECATIONS[josh_extras]=ash.extras
ASH_DEPRECATIONS[josh_pull]=ash.pull
ASH_DEPRECATIONS[josh_source]=ash.eval
ASH_DEPRECATIONS[josh_update]=ash.update
ASH_DEPRECATIONS[josh_upgrade]=ash.upgrade
ASH_DEPRECATIONS[path_last_modified]=fs.lm.many


autoload znt-history-widget
zle -N znt-history-widget

autoload znt-kill-widget
zle -N znt-kill-widget

autoload -U edit-command-line
zle -N edit-command-line
