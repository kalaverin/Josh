#!/bin/zsh


export PLUGINS_ROOT="$ZSH/custom/plugins"
ZSH_PACKAGES=(
    "https://github.com/MestreLion/git-tools.git $PLUGINS_ROOT/git-tools"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $PLUGINS_ROOT/autoupdate"
    "https://github.com/chrissicool/zsh-256color $PLUGINS_ROOT/zsh-256color"
    "https://github.com/djui/alias-tips.git $PLUGINS_ROOT/alias-tips"
    "https://github.com/facebook/PathPicker.git $PLUGINS_ROOT/fpp"
    "https://github.com/hlissner/zsh-autopair.git $PLUGINS_ROOT/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $PLUGINS_ROOT/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $PLUGINS_ROOT/zsh-async"
    "https://github.com/mollifier/anyframe.git $PLUGINS_ROOT/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $PLUGINS_ROOT/zsh-fuzzy-search-and-edit"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $PLUGINS_ROOT/zsh-syntax-highlighting-filetypes"
    "https://github.com/vifon/deer.git $PLUGINS_ROOT/deer"
    "https://github.com/wfxr/forgit.git $PLUGINS_ROOT/forgit"
    "https://github.com/zdharma-continuum/history-search-multi-word.git $PLUGINS_ROOT/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $PLUGINS_ROOT/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $PLUGINS_ROOT/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $PLUGINS_ROOT/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGINS_ROOT/zsh-syntax-highlighting"
)


# ——- first, clone oh-my-zsh as core

function omz.install {
    if [ -z "$ZSH" ]; then
        term $0 "something went wrong, ZSH path empty"
        return 1
    fi

    local cwd="$PWD"
    local url='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'

    if [ -z "$HTTP_GET" ]; then
        fail $0 "HTTP_GET isn't set"
        return 1
    fi

    if [ -d "$ZSH" ]; then
        info $0 "oh-my-zsh already installed in '$ZSH', just pull"
        builtin cd "$ZSH" && git pull origin; builtin cd "$cwd"

    else
        info $0 "deploy oh-my-zsh to '$ZSH'"
        eval.run "$HTTP_GET $url | CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$ZSH $SHELL -s - --unattended --keep-zshrc"

        if [ "$?" -gt 0 ] || [ ! -f "$ZSH/oh-my-zsh.sh" ]; then
            fail $0 "something went wrong"
            return 2
        fi
    fi
}


# ——- then clone git-based extensions

function omz.plugins {
    if [ -z "$PLUGINS_ROOT" ]; then
        info $0 "plugins dir isn't set"
        return 1
    fi

    [ ! -d "$PLUGINS_ROOT" ] && mkdir -p "$PLUGINS_ROOT"
    if [ ! -d "$PLUGINS_ROOT" ]; then
        fail $0 "binary dir doesn't exist, PLUGINS_ROOT '$PLUGINS_ROOT'"
        return 2
    fi

    info $0 "oh-my-zsh extensions home is '$PLUGINS_ROOT'"

    for pkg in "${ZSH_PACKAGES[@]}"; do
        local dst="$PLUGINS_ROOT/$(fs.basename $pkg)"
        if [ ! -x "$dst/.git" ]; then
            local verb='clone'
            $SHELL -c "git clone --depth 1 $pkg"

        else
            let fetch_every="${UPDATE_ZSH_DAYS:-1} * 86400"
            local last_fetch="$(fs.mtime "$dst/.git/FETCH_HEAD" 2>/dev/null)"
            [ -z "$last_fetch" ] && local last_fetch=0

            let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"
            if [ "$need_fetch" -gt 0 ]; then
                local verb='pull'
                local branch="$(git --git-dir="$dst/.git" --work-tree="$dst/" rev-parse --quiet --abbrev-ref HEAD)"

                if [ -z "$branch" ]; then
                    fail $0 "get branch for $pkg in '$dst'"
                    continue
                else
                    git --git-dir="$dst/.git" --work-tree="$dst/" pull origin "$branch"
                fi
            else
                local verb='skip fresh'
            fi

            if [ -x "$(which git-restore-mtime)" ]; then
                git-restore-mtime --skip-missing --quiet --work-tree "$dst/" --git-dir "$dst/.git/" 2>/dev/null
            fi
        fi

        if [ "$?" -gt 0 ]; then
            warn $0 "$verb error $pkg"
        else
            info $0 "$verb success $pkg"
        fi
    done

    info $0 "${#ZSH_PACKAGES[@]} extensions is up to date"
}
