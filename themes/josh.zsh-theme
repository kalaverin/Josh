# Michele Bologna's theme
# http://michelebologna.net
#
# This a theme for oh-my-zsh. Features a colored prompt with:
# * username@host: [jobs] [git] workdir %
# * hostname color is based on hostname characters. When using as root, the
# prompt shows only the hostname in red color.
# * [jobs], if applicable, counts the number of suspended jobs tty
# * [git], if applicable, represents the status of your git repo (more on that
# later)
#
# git prompt is inspired by official git contrib prompt:
# https://github.com/git/git/tree/master/contrib/completion/git-prompt.sh
# and it adds:
# * the current branch
# * '%' if there are untracked files
# * '$' if there are stashed changes
# * '*' if there are modified files
# * '+' if there are added files
# * '<' if local repo is behind remote repo
# * '>' if local repo is ahead remote repo
# * '=' if local repo is equal to remote repo (in sync)
# * '<>' if local repo is diverged

local green="%{$fg_bold[green]%}"
local red="%{$fg_bold[red]%}"
local cyan="%{$fg_bold[cyan]%}"
local yellow="%{$fg_bold[yellow]%}"
local blue="%{$fg_bold[blue]%}"
local magenta="%{$fg_bold[magenta]%}"
local white="%{$fg_bold[white]%}"
local gray="%{$fg[white]%}"
local dark="%{$fg_bold[black]%}"
local reset="%{$reset_color%}"

local -a color_array
color_array=($green $red $cyan $yellow $blue $magenta $white)

local username_normal_color=$white
local username_root_color=$red
local hostname_root_color=$red

# calculating hostname color with hostname characters
for i in `hostname`; local hostname_normal_color=$color_array[$[((#i))%7+1]]
local -a hostname_color
hostname_color=%(!.$hostname_root_color.$hostname_normal_color)

local current_dir_color="$gray"
local username_command="%n"
local hostname_command="%m"
local current_dir="%~"

local username_output="%(!..$username_normal_color$username_command$reset$dark@)"
local hostname_output="$hostname_color$hostname_command$reset"
local current_dir_output="$current_dir_color$current_dir$reset"
local jobs_bg="${yellow}%j$reset"
local last_command_output="%(?.%(!.$red.$green).$yellow)"

function _error_value() {
    local rvalue=$?
    if [[ $rvalue -ne 0 ]]; then
      echo "$dark$rvalue$reset "
    fi
}

function schroot_prompt_info() {
  if [ -n "$SCHROOT_CHROOT_NAME" ]; then
    echo "#$yellow${SCHROOT_CHROOT_NAME}$reset"
  fi
}

function virtualenv_prompt_info() {
    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -f "$VIRTUAL_ENV/__name__" ]; then
            local name=`cat $VIRTUAL_ENV/__name__`
        elif [ `basename $VIRTUAL_ENV` = "__" ]; then
            local name=$(basename $(dirname $VIRTUAL_ENV))
        else
            local name=$(basename $VIRTUAL_ENV)
        fi
        echo "$cyan$name$reset"
    fi
}

function pwd_abbr() {
    echo "$current_dir_color$(felix_pwd_abbr)$reset"
}

ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_UNTRACKED="$cyan+"
ZSH_THEME_GIT_PROMPT_MODIFIED="$red#"
ZSH_THEME_GIT_PROMPT_ADDED="$green*"
ZSH_THEME_GIT_PROMPT_STASHED=""
ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE=""
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="$white>"
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="$white<"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="$white<>"

PROMPT='$username_output$hostname_output$dark:$(pwd_abbr)%1(j. [$jobs_bg].)'
GIT_PROMPT='$(out=$(git_prompt_info)$(git_prompt_status)$(git_remote_status);if [[ -n $out ]]; then printf %s "$dark/$yellow$out$reset";fi)'
RIGHT_SIDE='$(_error_value)$(virtualenv_prompt_info)$(schroot_prompt_info)'
PROMPT+="$GIT_PROMPT "
export RPROMPT="$RIGHT_SIDE"
