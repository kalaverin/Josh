#!/bin/zsh

RUBY_ROOT="$HOME/.ruby"
RUBY_BINARIES="$RUBY_ROOT/bin"
RUBY_BIN="$(which ruby)"

export GEM_HOME="$HOME/.ruby"
export GEM_PATH="$HOME/.ruby"

[ ! -d "$RUBY_BINARIES" ] && mkdir -p "$RUBY_BINARIES"

[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    if [ -x "ruby" ]; then
        export GEM_HOME="$HOME/.ruby"
        if [ ! -x "$HOME/.ruby" ]; then
            mkdir -p "$HOME/.ruby"
        fi
    fi

    function ruby.init {
        return 0

        local cwd="$PWD"
        git clone https://github.com/rubygems/rubygems.git "$HOME/.ruby/.gem"
        cd "$HOME/.ruby/.gem"
        ruby setup.rb --prefix="~/.ruby"
        fs.link gem ~/.ruby/bin/gem
    }

    function ruby.deploy {
        ruby.init || return $?
        if [ ! -x "$RUBY_BIN" ]; then
            fail $0 "ruby '$RUBY_BIN' isn't found"
            return 1
        fi

        if [ ! -x $commands[gem] ]; then
            fail $0 "gem isn't found"
            return 1
        fi

        local retval=0
        for pkg in $@; do
            gem install --install-dir="$HOME/.ruby"  $pkg
            if [ "$?" -gt 0 ]; then
                local retval=1
            fi
        done
        return "$retval"
    }

    function ruby.install {
        ruby.deploy $@
    }
fi
