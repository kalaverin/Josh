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

# https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > jq static

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

# os dependent
if [ -n "$(uname | grep -i freebsd)" ]; then
    echo " + os: freebsd"
    su="su -m root -c"
    depends_command="pkg install -y fzf zsh git gnugrep py37-httpie jq pv gsed the_silver_searcher gnuls coreutils"

elif [ -n "$(uname | grep -i darwin)" ]; then
    runner="sh -c"
    echo " + os: macosx"
    depends_command="brew update && brew install grep fzf zsh git httpie jq pv python python@2"
    # gsed gnu-grep
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
        depends_command="apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git python3 python3-pip httpie jq pv"

    elif [ -n "$(uname -v | grep -i ubuntu)" ]; then
        echo " + os: ubuntu"
        su="su -l root -c"
        depends_command="apt-get update --yes --quiet || true && apt-get install --yes --quiet --no-remove tree zsh git python3 python3-pip httpie jq pv"
    else
        echo " - unsupported platform: $(uname -v)"
        return 1
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

# sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)"
