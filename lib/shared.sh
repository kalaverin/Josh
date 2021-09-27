local FZF_JUMPS='0123456789abcdefghijklmnopqrstuvwxyz'
local FZF="fzf --ansi --extended --info='inline' --no-mouse --marker='+' --pointer='>' --margin='0,0,0,0' --padding='0,0,0,0' --tiebreak=length,index --jump-labels=\"$FZF_JUMPS\" --bind='alt-space:jump-accept' --bind='alt-w:toggle-preview-wrap' --bind='ctrl-c:abort' --bind='ctrl-q:abort' --bind='end:preview-down' --bind='esc:cancel' --bind='home:preview-up' --bind='pgdn:preview-page-down' --bind='pgup:preview-page-up' --bind='shift-down:half-page-down' --bind='shift-up:half-page-up'"
[ $FZF_THEME ] && local FZF="$FZF --color=\"$FZF_THEME\""


local UNIQUE_SORT="runiq - | proximity-sort ."
local LINES_TO_LINE="sd '\n' ' ' | awk '{\$1=\$1};1'"


function cpu_count() {
    local cores=$(cat /proc/cpuinfo | ${JOSH_GREP:-'grep'} -Po 'processor\s+:\s*\d+\s*$' | wc -l)
    [ ! "$cores" ] && local cores=0
    return "$cores"
}

function get_preview_width() {
    let width="$COLUMNS - ($COLUMNS / 3 + 10)"
    [ $width -lt 84 ] && local width=84

    echo $width
    export JOSH_WIDTH=$width
}

function get_tempdir() {
    local path="$(dirname `mktemp -duq`)"
    [ ! -d "$path" ] && mkdir -p "$path"
    echo "$path"
}
