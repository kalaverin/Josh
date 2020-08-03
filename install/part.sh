#!/bin/sh
#
#  (curl -fsSL https://goo.gl/1MBc9t | sh) && exec zsh
#  (wget -qO - https://goo.gl/1MBc9t | sh) && exec zsh
# (fetch -qo - https://goo.gl/1MBc9t | sh) && exec zsh
#

ZSH="~/.josh"
ZSH=`sh -c "echo $ZSH"`
ZSH=`realpath $ZSH`
export ZSH="$ZSH"

JOSH="$ZSH/custom/plugins/josh"
export JOSH="$JOSH"

echo " * josh directory: $JOSH"

CURRENT_DATE=`date "+%Y%m%d_%H%M%S"`
CUSTOM_DIR_PLUGINS=$ZSH/custom/plugins

THIS="~"
THIS=`sh -c "echo $THIS"`
THIS=`realpath $THIS`

BACKUP_CONFIG="$THIS/.zshrc-$CURRENT_DATE"
CUSTOM_DIR_BIN="$THIS/.local/bin"
BACKUP_DIR_JOSH="$ZSH-$CURRENT_DATE"

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

if [ `which git` ]; then
    echo " * using git: `which git`"
    if [ -n "$VERBOSE" ]; then
        GIT_CLONE="`which git` clone --depth 1"
    else
        GIT_CLONE="`which git` clone --quiet --depth 1"
    fi
else
    echo ' - git must be installed! :-\'
    return 1
fi

if [ -f ~/.zshrc ]; then
    echo " + exists zshrc, backup: $BACKUP_CONFIG"
    cp -L ~/.zshrc $BACKUP_CONFIG
    if [ $? -gt 0 ]; then
        echo ' - backup failed!'
        return 1
    fi
    rm ~/.zshrc
fi

if [ -d $ZSH ]; then
    echo " + exists josh, backup: $BACKUP_DIR_JOSH"
    mv $ZSH $BACKUP_DIR_JOSH
fi

if [ -d $JOSH ]; then
    rm -rf $JOSH
fi

echo " + deploy oh-my-zsh: $ZSH"
($READ_URI 'https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh' | sed 's/^ *chsh/#/g' | sh)
if [ $? -gt 0 ]; then
    echo ' - failed oh-my-zsh!'
    return 1
fi

mkdir -p $JOSH
echo " + deploy josh: $JOSH"
$GIT_CLONE https://github.com/YaakovTooth/Josh.git $JOSH
if [ $? -gt 0 ]; then
    echo ' - failed josh!'
    return 1
fi

echo " + third-party extensions: $CUSTOM_DIR_PLUGINS"
(
    $GIT_CLONE https://github.com/chrissicool/zsh-256color $CUSTOM_DIR_PLUGINS/zsh-256color && \
    $GIT_CLONE https://github.com/djui/alias-tips.git $CUSTOM_DIR_PLUGINS/alias-tips && \
    $GIT_CLONE https://github.com/felixgravila/zsh-abbr-path.git $CUSTOM_DIR_PLUGINS/zsh-abbr-path && \
    $GIT_CLONE https://github.com/horosgrisa/mysql-colorize $CUSTOM_DIR_PLUGINS/mysql-colorize && \
    $GIT_CLONE https://github.com/mafredri/zsh-async.git $CUSTOM_DIR_PLUGINS/zsh-async && \
    $GIT_CLONE https://github.com/supercrabtree/k $CUSTOM_DIR_PLUGINS/k && \
    $GIT_CLONE https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $CUSTOM_DIR_PLUGINS/autoupdate && \
    $GIT_CLONE https://github.com/zsh-users/zsh-syntax-highlighting.git $CUSTOM_DIR_PLUGINS/zsh-syntax-highlighting && \
    $GIT_CLONE https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $CUSTOM_DIR_PLUGINS/zsh-syntax-highlighting-filetypes && \
    $GIT_CLONE https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $CUSTOM_DIR_PLUGINS/zsh-fuzzy-search-and-edit && \
    # $GIT_CLONE https://github.com/zdharma/fast-syntax-highlighting.git $CUSTOM_DIR_PLUGINS/fast-syntax-highlighting && \
    $GIT_CLONE https://github.com/zdharma/history-search-multi-word.git $CUSTOM_DIR_PLUGINS/history-search-multi-word && \
    $GIT_CLONE https://github.com/zlsun/solarized-man.git $CUSTOM_DIR_PLUGINS/solarized-man && \
    $GIT_CLONE https://github.com/zsh-users/zsh-autosuggestions $CUSTOM_DIR_PLUGINS/zsh-autosuggestions && \
    $GIT_CLONE https://github.com/zsh-users/zsh-completions $CUSTOM_DIR_PLUGINS/zsh-completions && \
    $GIT_CLONE https://github.com/mollifier/anyframe.git $CUSTOM_DIR_PLUGINS/anyframe && \
    $GIT_CLONE https://github.com/so-fancy/diff-so-fancy.git $CUSTOM_DIR_PLUGINS/diff-so-fancy && \
    $GIT_CLONE https://github.com/b4b4r07/emoji-cli $CUSTOM_DIR_PLUGINS/emoji-cli && \
    $GIT_CLONE https://github.com/wfxr/forgit.git $CUSTOM_DIR_PLUGINS/forgit && \
    $GIT_CLONE https://github.com/hlissner/zsh-autopair.git $CUSTOM_DIR_PLUGINS/zsh-autopair && \
    $GIT_CLONE https://github.com/leophys/zsh-plugin-fzf-finder.git $CUSTOM_DIR_PLUGINS/zsh-plugin-fzf-finder && \
    $GIT_CLONE --recursive https://github.com/joel-porquet/zsh-dircolors-solarized.git $CUSTOM_DIR_PLUGINS/zsh-dircolors-solarized
)
if [ $? -gt 0 ]; then
    echo ' - failed extensions!'
    return 1
fi

if [ `which fzf` ]; then
    echo " * using fzf: `which fzf`"
else
    if [ ! -d $CUSTOM_DIR_BIN ]; then
        echo " + deploy fzf: $CUSTOM_DIR_BIN/fzf"
        mkdir -p $CUSTOM_DIR_BIN
    else
        if [ -f $CUSTOM_DIR_BIN/fzf ]; then
            rm $CUSTOM_DIR_BIN/fzf
        fi
    fi

    tempdir=`mktemp -d`
    rm -rf $tempdir
    $GIT_CLONE https://github.com/junegunn/fzf.git $tempdir && $tempdir/install --completion --key-bindings --update-rc --bin && cp -f $tempdir/bin/fzf $CUSTOM_DIR_BIN/fzf && rm -rf $tempdir
    if [ $? -gt 0 ]; then
        echo " + failed fzf: $CUSTOM_DIR_BIN/fzf"
    fi
fi

if [ -e ~/.zshrc ]; then
    echo ' + create links: ~/.zshrc, etc'
    rm ~/.zshrc
fi

ln -s $JOSH/.zshrc ~/.zshrc && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme
if [ $? -gt 0 ]; then
    echo ' - failed links!'
    return 1
fi

git config --global color.ui auto
git config --global color.branch auto
git config --global color.diff auto
git config --global color.interactive auto
git config --global color.status auto
git config --global color.grep auto
git config --global color.pager true
git config --global color.decorate auto
git config --global color.showbranch auto
if [ -n "$(uname | grep -i freebsd)" ]; then
    git config --global core.pager "delta --commit-style plain --file-style plain --hunk-style plain --highlight-removed"
else
    git config --global core.pager "delta --commit-style='yellow ul' --commit-decoration-style='' --file-style='cyan ul' --file-decoration-style='' --hunk-style plain --zero-style='dim syntax' --24-bit-color='always' --minus-style='syntax #330000' --plus-style='syntax #002200' --file-modified-label='M' --file-removed-label='D' --file-added-label='A' --file-renamed-label='R' --line-numbers-left-format='{nm:^4}' --line-numbers --navigate"
fi


if [ $BACKUP_DIR_JOSH ]; then
    if [ -d $BACKUP_DIR_JOSH ]; then
        echo " * backup removed: $BACKUP_DIR_JOSH"
        rm -rf $BACKUP_DIR_JOSH
    fi
fi

if [ -f "$THIS/.nanorc" ]; then
    # https://github.com/scopatz/nanorc
    echo " * nano config: $THIS/.nanorc"
else
    if [ -n "$(uname | grep -i freebsd)" ]; then
        if [ -d /usr/local/share/nano/ ]; then
            find /usr/local/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $THIS/.nanorc
            echo " + nano config: $THIS/.nanorc"
        fi
    elif [ -n "$(uname | grep -i linux)" ]; then
        if [ -d /usr/share/nano/ ]; then
            find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> $THIS/.nanorc
            echo " + nano config: $THIS/.nanorc"
        fi
    fi
fi

cd ~
echo ' + oh my josh!'
