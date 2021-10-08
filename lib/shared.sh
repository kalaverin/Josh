local FZF_JUMPS='0123456789abcdefghijklmnopqrstuvwxyz'
local FZF="fzf --ansi --extended --info='inline' --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' --padding='0,0,0,0' --tiebreak=length,index --jump-labels=\"$FZF_JUMPS\" --bind='alt-space:jump-accept' --bind='alt-w:toggle-preview-wrap' --bind='ctrl-c:abort' --bind='ctrl-q:abort' --bind='end:preview-down' --bind='esc:cancel' --bind='home:preview-up' --bind='pgdn:preview-page-down' --bind='pgup:preview-page-up' --bind='shift-down:half-page-down' --bind='shift-up:half-page-up'"
[ $FZF_THEME ] && local FZF="$FZF --color=\"$FZF_THEME\""


local UNIQUE_SORT="runiq - | proximity-sort ."
local LINES_TO_LINE="sd '\n' ' ' | awk '{\$1=\$1};1'"


function cpu_count() {
    local cores=$(${JOSH_GREP:-'grep'} --count -Po 'processor\s+:\s*\d+\s*$' /proc/cpuinfo)
    [ ! "$cores" ] && local cores=0
    return "$cores"
}

function get_preview_width() {
    let width="$COLUMNS - ($COLUMNS / 3 + 10)"
    [ $width -lt 84 ] && local width=84

    echo "$width"
    export JOSH_WIDTH="$width"
}

function get_tempdir() {
    local result="$(dirname `mktemp -duq`)"
    [ ! -x "$result" ] && mkdir -p "$result"
    echo "$result"
}


function mkcd {
    [ -z "$1" ] && return 1
    mkdir -p "$*" && cd "$*"
}


function run_show() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>&2
}


function run_silent() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    echo " -> $cmd" 1>&2
    eval ${cmd} 1>/dev/null 2>/dev/null
}


function run_hide() {
    local cmd="$*"
    [ -z "$cmd" ] && return 1
    eval ${cmd} 1>/dev/null 2>/dev/null
}


last_modified() {
    local args="$*"
    [ -x "$1" ] && local args="`realpath $1` ${@:2}"
    local cmd="find $args -printf \"%T@ %p\n\" | sort -n | tail -n 1"
    eval ${cmd}
}
