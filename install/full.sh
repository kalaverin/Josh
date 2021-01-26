#!/bin/sh
#
#  (curl -fsSL https://goo.gl/NCF9so | sh) && exec zsh
#  (wget -qO - https://goo.gl/NCF9so | sh) && exec zsh
# (fetch -qo - https://goo.gl/NCF9so | sh) && exec zsh

ZSH="~/.josh"
ZSH=`sh -c "echo $ZSH"`
ZSH=`realpath $ZSH`
export ZSH="$ZSH"

JOSH_USER_URI="https://raw.githubusercontent.com/YaakovTooth/Josh/master/install/part.sh?$RANDOM"
DEB_FDF="https://github.com/sharkdp/fd/releases/download/v8.1.1/fd_8.1.1_amd64.deb"
DEB_BAT="https://github.com/sharkdp/bat/releases/download/v0.15.4/bat_0.15.4_amd64.deb"
DEB_GDL="https://github.com/dandavison/delta/releases/download/0.3.0/git-delta_0.3.0_amd64.deb"

if [ -n "$(uname -v | grep -i ubuntu)" ]; then
    alias fd='fdfind'
elif [ -n "$(uname -v | grep -i debian)" ]; then
    alias fd='fdfind'
fi

# select content fetcher
if [ -n "$READ_URI" ]; then
    echo " * using: $READ_URI"

elif [ `which curl` ]; then
    READ_URI="`which curl` -fsSL"
    echo " * using curl: $READ_URI"

elif [ `which wget` ]; then
    READ_URI="`which wget` -qO -"
    echo " * using wget: $READ_URI"

elif [ `which fetch` ]; then
    READ_URI="`which fetch` -qo - "
    echo " * using fetch: $READ_URI"

else
    echo ' - please, install curl or wget :-\'
fi


# select sudo or su
if [ `which sudo` ]; then
    runner="`which sudo` sh -c"
    echo " + sudo detected: $runner"
else
    runner="$su"
    echo " - sudo not found, use su"
fi

# #@todo https://github.com/sharkdp/fd и сделать нормальные пути во фре

# os dependent
if [ -n "$(uname | grep -i freebsd)" ]; then
    echo " + os: freebsd"
    su="su -m root -c"
    depends_command="pkg install -y fzf zsh git gnugrep py37-httpie jq pv bat fd-find gsed the_silver_searcher gnuls git-delta coreutils cargo"

elif [ -n "$(uname | grep -i darwin)" ]; then
    runner="sh -c"
    echo " + os: macosx"
    depends_command="brew update && brew install grep fzf zsh git httpie jq pv bat python python@2"
    # fd-find gsed gnu-grep
    if [ ! -d '/usr/local/Homebrew' ]; then
        echo " - homebrew not found"
        BIN_RUBY="`which ruby`"
        if [ ! -f $BIN_RUBY ]; then
            echo ' - please, install ruby, homebrew and retry'
            return 1
        else
            $READ_URI 'https://raw.githubusercontent.com/Homebrew/install/master/install' | $BIN_RUBY
            if [ $? -gt 0 ]; then
                echo ' - please, install homebrew and retry'
                return 1
            fi
        fi
    fi

elif [ -n "$(uname | grep -i linux)" ]; then
    if [ -n "$(uname -v | grep -i debian)" ]; then
        echo " + os: debian"
        su="su -l root -c"
        depends_command="apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git python3 python3-pip httpie jq pv cargo"

    elif [ -n "$(uname -v | grep -i ubuntu)" ]; then
        echo " + os: ubuntu"
        su="su -l root -c"
        depends_command="apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git python3 python3-pip httpie jq pv cargo"
    else
        echo " - unsupported platform: $(uname -v)"
        return 1
    fi

    BIN_BAT = `which bat`
    if [ $BIN_BAT ]; then
        echo " + bat detected: $BIN_BAT"
    else
        echo " - bat not found"
        depends_command="$depends_command && $READ_URI $DEB_BAT > /tmp/pkg.deb && dpkg -i /tmp/pkg.deb && unlink /tmp/pkg.deb"
    fi

    BIN_FDF = `which fdfind`
    if [ $BIN_FDF ]; then
        echo " + fdfind detected: $BIN_FDF"
    else
        echo " - fdfind not found"
        depends_command="$depends_command && $READ_URI $DEB_FDF > /tmp/pkg.deb && dpkg -i /tmp/pkg.deb && unlink /tmp/pkg.deb"
    fi

    BIN_GDL = `which delta`
    if [ $BIN_GDL ]; then
        echo " + git-delta detected: $BIN_GDL"
    else
        echo " - git-delta not found"
        depends_command="$depends_command && $READ_URI $DEB_GDL > /tmp/pkg.deb && dpkg -i /tmp/pkg.deb && unlink /tmp/pkg.deb"
    fi
fi

echo " + system: $runner $depends_command"
$runner "$depends_command"
if [ $? -gt 0 ]; then
    echo " - something wrong, install deps with hands and run: ($READ_URI $JOSH_USER_URI | sh) && zsh"
    return 1
fi

$READ_URI $JOSH_USER_URI | sh
if [ $? -gt 0 ]; then
    echo ' - something wrong :-\'
    return 1
fi
echo ' + all ok, stay tuned!'
