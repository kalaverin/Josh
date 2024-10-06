#!/bin/zsh

export HOMEBREW_AUTO_UPDATE_SECS="86400"
export HOMEBREW_NO_ENV_HINTS="1"
# export HOMEBREW_NO_AUTO_UPDATE=""


[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    BREW_REС_PACKAGES=(
        ag    # silver searcher, another one fast source grep on golang
        htop  # instead system-wide htop
        jq    # JSON swiss-knife, format, highlight, traversal and query tool
        pv    # contatenate pipes with monitoring
        tmux  # terminal multiplexer
        tree  # hierarchy explore tool
        ncdu
        git
        findutils
        fzf
        gnu-tar
        grep
        gsed
        micro
        nano
    )

    function brew.root {
        local curl_bin git_bin ruby_bin retval

        local curl_bin="curl"
        local git_bin="git"
        local ruby_bin="ruby"

        if [ "$ASH_OS" = "BSD" ]; then
            if [ ! -x $commands[gem] ]; then
                warn $0 "gem isn't installed"
                return 1
            fi

        elif [ "$ASH_OS" = "MAC" ]; then
            fail $0 "'$ASH_OS have native implementation': $(uname -srv)"
            return 1
        fi

        curl_bin="$(which "$curl_bin")"; retval="$?"
        if [ ! -x "$curl_bin" ] || [ "$retval" -ne 0 ]; then
            fail $0 "curl binary isn't found"
            return 2
        fi
        export HOMEBREW_CURL_PATH="$curl_bin"

        git_bin="$(which "$git_bin")"; retval="$?"
        if [ ! -x "$git_bin" ] || [ "$retval" -ne 0 ]; then
            fail $0 "git binary isn't found"
            return 3
        fi
        export HOMEBREW_GIT_PATH="$git_bin"

        ruby_bin="$(which "$ruby_bin")"; retval="$?"
        if [ ! -x "$ruby_bin" ] || [ "$retval" -ne 0 ]; then
            fail $0 "ruby binary isn't found, may be can make symlink for? try: fs.link ruby /usr/local/bin/ruby33"
            return 3
        fi
        echo "$HOME/.brew"
        return 0
    }

    function brew.bin {
        local root="$(brew.root)"
        [ -z "$root" ] && return 1

        local bin="$root/bin/brew"
        if [ ! -x "$bin" ]; then
            fail $0 "brew binary '$root/bin/brew' isn't found"
            return 2
        fi

        echo "$bin"
        return 0
    }

    function brew.deploy {
        local root="$(brew.root)"
        [ -z "$root" ] && return 1

        if [ -d "$root" ]; then
            fail $0 "brew path '$root' exists"
            return 2

        elif [ ! -d "$(fs.dirname $root)" ]; then
            fail $0 "brew path '$root' subroot isn't found"
            return 3
        fi

        git clone --depth 1 "https://github.com/Homebrew/brew" "$root" && \
        eval $($root/bin/brew shellenv) && \
        path.rehash

        local bin="$(brew.bin)"
        [ ! -x "$bin" ] && return 4
        $bin update --force

        return "$?"
    }

    function brew.init {
        local root="$(brew.root)"
        [ -z "$root" ] && return 1

        if [ ! -x "$root/bin/brew" ]; then
            warn $0 "brew binary '$root/bin/brew' isn't found, deploy now"
            brew.deploy || return 2
        fi

        brew.env
    }

    function brew.install {
        brew.init || return 1

        if [ -z "$*" ]; then
            fail $0 "nothing to do"
            return 2
        fi

        local brew="$(brew.bin)"
        [ ! -x "$brew" ] && return 3

        for row in $*; do
            run.show "$brew install $row"

            local exe="$(fs.basename $row)"
            if [ -z "$exe" ]; then
                fail $0 "basename for '$row' empty"
                continue
            fi

            local bin="$HOMEBREW_PREFIX/bin/$exe"
            if [ -x "$bin" ]; then
                local dst="$(fs.link "$bin")"
                info $0 "$dst -> $(which $exe)"
            fi
        done
    }

    function brew.extras {
        run.show "brew.install $BREW_REС_PACKAGES"
        return 0
    }

    function brew.update {
        brew.env || return 1

        local bin="$(brew.bin)"
        [ ! -x "$bin" ] && return 2
        $bin update && $bin upgrade
    }

    function brew.env {
        local root="$(brew.root 2>/dev/null)"
        [ -z "$root" ] && return 1
        [ ! -x "$root/bin/brew" ] && return 2

        eval $($root/bin/brew shellenv)
        HOMEBREW_CELLAR="$root/Cellar"
        HOMEBREW_PREFIX="$root"
        HOMEBREW_REPOSITORY="$root"
        HOMEBREW_SHELLENV_PREFIX="$root"
        path.rehash
    }
fi
