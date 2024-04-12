#!/bin/zsh

CARGO_BINARIES="$HOME/.cargo/bin"
[ ! -d "$CARGO_BINARIES" ] && mkdir -p "$CARGO_BINARIES"

[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    # https://rawcdn.githack.com/nabijaczleweli/cargo-update/man/cargo-install-update.1.html
    # exclude tabulate, add git based, move temp to ram

    CARGO_REQ_PACKAGES=(
        bat              # modern replace for cat with syntax highlight
        cargo-update     # packages for auto-update installed crates
        fd-find          # fd, fast replace for find for humans
        git-delta        # fast replace for git delta with steroids
        git-interactive-rebase-tool
        lsd              # fast ls replacement
        petname          # generate human readable strings
        proximity-sort   # path sorter
        ripgrep          # rg, fast replace for grep -ri for humans
        runiq            # fast uniq replacement
        scotty           # directory crawling statistics with search
        sd               # fast sed replacement for humans
        starship         # shell prompt
        tabulate         # autodetect columns in stdin and tabulate
        vivid            # ls colors themes selections system
    )
    CARGO_REC_PACKAGES=(
        bingrep          # extract and grep strings from binaries
        broot            # console file manager
        bump-bin         # versions with semver specification
        cargo-whatis     # fast chit replacement
        cfonts           # colored terminal text with fonts
        chit             # crates info, just type: chit <any>
        cork             # repl hex calculator
        csview           # for commas, tabs, etc
        ctv              # fast tree
        diffsitter       # AST based diff
        dirstat-rs       # ds, du replace, summary tree
        diskus           # fast du -sh replacement
        dsmsg            # phrases from Dark Souls generator
        dtool            # code decode swiss knife
        du-dust          # dust, du replace, verbose tree
        dull             # strip any ANSI (color) sequences from pipe
        dupe-krill       # replace similar (by hash) files with hardlinks
        durt             # du replace, just sum
        dusage           # df replace
        easypassword     # password generator
        gfold            # git reps in directory branches status
        gip              # show my ip
        git-bonsai       # full features analyze and remove unnecessary branches
        git-eq           # autocommit all changes to new branch and push it
        git-gone         # remove local branches
        git-hist         # git history for selected file
        git-hooks-dispatch
        git-summary      # fast gfold replacement
        git-trim         # remove local branches when remote merged
        git-who          # list branches with date, author and merge status
        hexyl            # hex viewer
        hgrep            # wonderful grep with syntax highlight
        hj               # http response into json
        ignoreit         # powerful .gitignore for any languages
        igrep            # interactive ripgrep
        jaq              # json query and manipulating tool
        jfmt             # minifier
        jira-terminal    # jira client
        jql              # select values by path from JSON input for humans
        jsonfmt          # another JSON minifier
        kalker           # powerful terminal interactive calculator
        krabby           # show pokemon
        lnx              # xargs replacement, pass args from stdio
        loadem           # website load maker
        mdcat            # Markdown files rendered viewer
        miniserve        # directory serving over http
        parallel-disk-usage # pdu, parallel and fast du
        parallel-sh      # shell commands parallizer
        pastel           # color logging
        pgen             # password generator
        pipr             # shell pipelines tui helper with partial execution
        pouf             # many data formats faker
        procs            # ps aux replacement for humans
        ptit             # print images into terminal
        qrrs             # qr code terminal tool
        quickdash        # hasher
        rcrawl           # very fast file searcher by pattern in directory
        readable-name-generator
        rhit             # very fast nginx log analyzer with graphical stats
        rjo              # JSON generator by key->value
        rm-improved      # rip, powerful rm replacement with trashcan
        ruplacer         # refactoring tool, like sed for directory
        ry               # jq for yamls
        sbyte            # hexeditor
        so               # command line TUI full featured stack overflow questions
        tere             # jumps over directories
        trippy           # network diagnosis tool
        tuc              # cut replacer
        viu              # print images into terminal
        watchexec-cli    # watchdog runner, useful for dev autorestart
        xcp              # cp replacement
        xh               # rust httpie replacement
        xkpwgen          # generate human readable strings
        xt               # json, yaml, toml and msgpack converter
        yj               # YAML to JSON converter
    )
    CARGO_OPT_PACKAGES=(
        b0x
        arp-scan
        basecracker      # BASExx encode, decode and crack
        bkt              # invocation cache tool
        caster           # expose stdout via http
        ch4              # plain dns client, dig like
        difftastic       # diff colored visualizer
        doh-client       # full featured client with caching
        doh-proxy        # doh servier, proxy to plain dns
        dssim            # pictures similarity compare tool
        duf              # miniserver analogue
        enquirer         # for zsh interactive scripting
        fast-ssh         # tui for .ssh/config
        feroxbuster      # agressively website dumper
        genact           # console activity generator
        gitui            # full featured tui git client
        grep_bin         # another binary grep
        htmlq            # jq for html
        httm             # file versions tool
        https-dns        # simple client
        hyperfine        # time replacement and benchmarking tool
        investments      # stocks tools
        ipgeo            # geoloc by hostname/ip
        just             # command runner like make
        limber           # elasticsearch importer/exporter
        logtail          # graphical tail logs in termial
        lolcate-rs       # blazing fast filesystem database
        mprober          # top like tool
        multi-tunnel     # multiple SSH tunnels
        names            # another names generator
        navi             # local TUI cheatsheets with repositories
        netperf          # simple network perftool
        oha              # tui tool for website benchmarking
        onefetch         # graphical statistics for git repository
        oreo             # NAT bypass tunnels, like ngrok
        rust-latest      # actual rustup version fetcher
        rustscan         # scanner around nmap
        slick            # starship fast replacement
        sniffglue        # network sniffer
        ss-rs            # shadowsocks server and client
        streampager      # less for streams
        termatrix        # matrix screensaver
        termscp          # tui for scp, sftp, ftp, s3
        tickrs           # realtime ticker
        tidy-viewer      # csv prettry printer
        tobaru           # port forwarding tool
        toluol           # DNS queries maker
        x8               # websites scan tool
        ytop             # htop analogue
        ztop             # zfs datasets iostat
    )

    CARGO_BIN="$CARGO_BINARIES/cargo"

    function cargo.init {
        local cache_exe="$CARGO_BINARIES/sccache"

        if [ -z "$HTTP_GET" ]; then
            term $0 "HTTP_GET isn't set"
            return 1

        elif [ ! -x "$CARGO_BIN" ]; then
            export RUSTC_WRAPPER=""
            unset RUSTC_WRAPPER

            local caller="`which bash`"
            if [ ! -x "$caller" ]; then
                warn $0 "bash isn't exists, try default sh"
                local caller="`which sh`"
                if [ ! -x "$caller" ]; then
                    term $0 "sh isn't exists too, halt"
                    return 2
                fi
            fi

            url='https://sh.rustup.rs'

            $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME="$HOME/.rustup" CARGO_HOME="$HOME/.cargo" RUSTUP_INIT_SKIP_PATH_CHECK=yes $caller -s - --profile minimal --no-modify-path -y >&2

            if [ "$?" -gt 0 ] || [ ! -x "$CARGO_BIN" ]; then
                term $0 "cargo '$CARGO_BIN' isn't installed"
                return 127
            else
                info $0 "$($CARGO_BIN --version) in '$CARGO_BIN'"
            fi
        fi

        export PATH="$CARGO_BINARIES:$PATH"

        if [ ! -x "$cache_exe" ]; then
            $CARGO_BIN install sccache
            if [ ! -x "$cache_exe" ]; then
                warn $0 "sccache '$cache_exe' isn't compiled"
            fi
        fi

        if [ -z "$RUSTC_WRAPPER" ] || [ ! -x "$RUSTC_WRAPPER" ]; then
            if [ -x "$cache_exe" ]; then
                export RUSTC_WRAPPER="$cache_exe"

            elif [ -x "`which sccache`" ]; then
                export RUSTC_WRAPPER="`which sccache`"

            else
                export RUSTC_WRAPPER=""
                unset RUSTC_WRAPPER
                warn $0 "sccache doesn't exists"
            fi
        fi

        local update_exe="$CARGO_BINARIES/cargo-install-update"
        if [ ! -x "$update_exe" ]; then
            $CARGO_BIN install cargo-update >&2
            if [ ! -x "$update_exe" ]; then
                warn $0 "cargo-update '$update_exe' isn't compiled"
            fi
        fi

        return 0
    }

    function cargo.deploy {
        cargo.init || return $?
        if [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo '$CARGO_BIN' isn't found"
            return 1
        fi

        $SHELL -c "$(fs.realpath $CARGO_BINARIES/rustup) update"

        local retval=0
        for pkg in $@; do
            $CARGO_BIN install $pkg
            if [ "$?" -gt 0 ]; then
                local retval=1
            fi
        done
        return "$retval"
    }

    function cargo.extras {
        cargo.install "$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
        return 0
    }

    function cargo.install.all {
        cargo.install "$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES $CARGO_OPT_PACKAGES"
        return 0
    }

    function cargo.install.list {
        cargo.init || return "$?"

        if [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo exe $CARGO_BIN isn't found!"
            return 1
        fi
        echo "$($CARGO_BIN install --list | egrep '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ')"
    }

    function cargo.install {
        cargo.init || return $?
        if [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo exe $CARGO_BIN isn't found!"
            return 1
        fi

        if [ -n "$*" ]; then
            local selected="$*"
        else
            local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
        fi

        local installed_regex="($(
            cargo.install.list | sed -z 's:\n: :g' | \
            sed 's/ *$//' | sd '\b +\b' '|'))"

        local missing_packages="$(
            echo "$selected" | sd '\s+' '\n' | grep -Pv "$installed_regex" | \
            sed -z 's:\n: :g' | sed 's/ *$//')"

        [ -z "$missing_packages" ] && return 0

        local autoinstall="$(
            echo "$*" | sd '\s+' '\n' | grep -Pv "$installed_regex" | \
            sed -z 's:\n: :g' | sed 's/ *$//')"

        if [ -n "$autoinstall" ]; then
            local packages="$autoinstall"
        else
            local packages="$($SHELL -c "
                echo "$missing_packages" \
                | sd ' +' '\n' \
                | proximity-sort - \
                | $FZF \
                    --multi \
                    --nth=2 \
                    --tiebreak='index' \
                    --layout=reverse-list \
                    --prompt='install > ' \
                    --preview='chit {1}' \
                    --preview-window="left:`misc.preview.width`:noborder" \
                | $UNIQUE_SORT | $LINES_TO_LINE
            ")"
        fi

        if [ -n "$packages" ]; then
            run.show "$CARGO_BIN install $packages"
        fi
    }

    function cargo.remove {
        cargo.init || return $?

        if [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo exe $CARGO_BIN isn't found!"
            return 1
        fi

        local required_regex="($(echo "$CARGO_REQ_PACKAGES" | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'))"

        if [ -n "$*" ]; then
            local selected="$*"
        else
            local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
        fi

        local installed_regex="($(
            cargo.install.list | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'))"

        local installed_packages="$(
            echo "$selected" | sd '\s+' '\n' | \
            grep -P "$installed_regex" | \
            grep -Pv "$required_regex" | \
            sed -z 's:\n: :g' | sed 's/ *$//')"

        [ -z "$installed_packages" ] && return 0

        local autoremove="$(
            echo "$*" | sd '\s+' '\n' | \
            grep -P "$installed_regex" | \
            grep -Pv "$required_regex" | \
            sed -z 's:\n: :g' | sed 's/ *$//')"

        if [ -n "$autoremove" ]; then
            local packages="$autoremove"
        else
            local packages="$($SHELL -c "
                echo "$installed_packages" \
                | sd ' +' '\n' \
                | proximity-sort - \
                | $FZF \
                    --multi \
                    --nth=2 \
                    --tiebreak='index' \
                    --layout=reverse-list \
                    --prompt='uninstall > ' \
                    --preview='chit {1}' \
                    --preview-window="left:`misc.preview.width`:noborder" \
                | $UNIQUE_SORT | $LINES_TO_LINE
            ")"
        fi

        if [ -n "$packages" ]; then
            run.show "$CARGO_BIN uninstall $packages"
        fi
    }

    function cargo.update.all {
        local packages="$(cargo.install.list | sed -z 's:\n: :g' | sed 's/ *$//')"
        if [ -n "$packages" ]; then
            $SHELL -c "$CARGO_BIN install --force $packages"
        fi
    }

    function cargo.update {
        cargo.init || return "$?"

        if [ ! -x "$CARGO_BIN" ]; then
            fail $0 "cargo exe $CARGO_BIN isn't found!"
            return 1
        fi

        local update_exe="$CARGO_BINARIES/cargo-install-update"
        if [ ! -x "$update_exe" ]; then
            fail $0 "cargo-update exe $update_exe isn't found!"
            return 1
        fi

        $SHELL -c "$(fs.realpath $CARGO_BINARIES/rustup) update"
        $CARGO_BIN install-update --all
        return "$?"
    }
fi
