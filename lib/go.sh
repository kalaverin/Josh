#!/bin/zsh

GO_ROOT="$HOME/go"
GO_BINARIES="$GO_ROOT/bin"
GO_BIN="$GO_BINARIES/go"
export GOROOT="$GO_ROOT"
export GOPATH="$HOME/.go"

[ ! -d "$GO_BINARIES" ] && mkdir -p "$GO_BINARIES"

[ -z "$SOURCES_CACHE" ] && declare -aUg SOURCES_CACHE=() && SOURCES_CACHE+=($0)

local THIS_SOURCE="$(fs.gethash "$0")"
if [ -n "$THIS_SOURCE" ] && [[ "${SOURCES_CACHE[(Ie)$THIS_SOURCE]}" -eq 0 ]]; then
    SOURCES_CACHE+=("$THIS_SOURCE")

    GO_REQ_PACKAGES=(
        github.com/zyedidia/eget@latest
        github.com/direnv/direnv@latest
        github.com/Akimon658/gup@latest
        github.com/joerdav/xc/cmd/xc@latest
    )
    GO_REC_PACKAGES=(
        github.com/Gelio/go-global-update@latest
        github.com/asciimoo/wuzz@latest # cli http inspector
        github.com/sosedoff/pgweb@latest  # postgres web admin
        github.com/schachmat/wego@latest  # weather in terminal
        github.com/claudiodangelis/qrcp@latest  # share file to network with qr
        mvdan.cc/sh/v3/cmd/gosh@latest  # shell interpreter
        mvdan.cc/sh/v3/cmd/shfmt@latest  # shell formatter
    )
    EGET_REQ_PACKAGES=(
        # direnv/direnv
        # zyedidia/micro
        # https://github.com/sqshq/sampler
    )

    function go.init {
        local filename retval result

        if [ -z "$HTTP_GET" ]; then
            term $0 "HTTP_GET isn't set"
            return 1

        elif [ ! -x $commands[jq] ]; then
            term $0 "jq isn't installed"
            return 2

        elif [ ! -x "$GO_BIN" ]; then
            warn $0 "go isn't installed: $GO_BIN"
            url='https://go.dev/dl/?mode=json'

            if [ "$ASH_OS" = "BSD" ]; then
                local goos="freebsd"
            elif [ "$ASH_OS" = "MAC" ]; then
                local goos="darwin"
            elif [ "$ASH_OS" = "LINUX" ]; then
                local goos="linux"
            else
                term $0 "OS isn't supported: $ASH_OS"
            fi
            ASH_ARCH='amd64'

            temp_dir="$(temp.dir)" || return "$?"
            temp_file="$temp_dir/go-$USER.json"

            run.show "$HTTP_GET '$url' > '$temp_file'"
            filename="$(cat "$temp_file" | jq --raw-output --sort-keys "sort_by(.version) | last | .files[] | select(.version | startswith(\"go\")) | select(.os | startswith(\"$goos\")) | select(.arch | startswith(\"$ASH_ARCH\")) | select(.kind | startswith(\"archive\")) | .filename")"; retval="$?"
            unlink "$temp_file"

            if [ -z "$filename" ] || [ "$retval" -ne 0 ]; then
                $HTTP_GET "$url" |  --raw-output --sort-keys "sort_by(.version) | last | .files[]" >&2
                term $0 "couldn't find go package for $goos/$ASH_ARCH"
                return 3
            fi

            if [ ! -f "$GO_ROOT/$filename" ]; then
                info $0 "downloading latest $filename for $goos/$ASH_ARCH"
                run.show "$HTTP_GET 'https://golang.org/dl/$filename' > '$GO_ROOT/$filename'"
                retval="$?"

                if [ "$retval" -ne 0 ] || [ ! -f "$GO_ROOT/$filename" ]; then
                    term $0 "couldn't download go package"
                    return 4
                fi
                info $0 "downloaded $filename to $GO_ROOT, extract"
            fi

            local cwd="$PWD"
            cd "$GO_ROOT" && tar -xzf "$filename" && cp -Rf go/. . && rm -rf go/ && cd "$cwd"; retval="$?"

            if [ "$retval" -ne 0 ]; then
                term $0 "couldn't extract go package"
                return 5

            elif [ ! -x "$GO_BINARIES/go" ]; then
                term $0 "go '$GO_BIN' isn't installed"
                return 6
            else
                info $0 "installed $($GO_BIN version) in '$GO_BIN'"
                unlink "$GO_ROOT/$filename"
            fi
        fi
        export PATH="$GO_ROOT:$PATH"
        return 0
    }

    function go.deploy {
        go.init || return $?
        if [ ! -x "$GO_BIN" ]; then
            fail $0 "go '$GO_BIN' isn't found"
            return 1
        fi

        local retval=0
        local packages="$*"
        for pkg in "${(@u)${(z)packages}}"; do
            $GO_BIN install $pkg
            if [ "$?" -gt 0 ]; then
                local retval=1
            fi
        done
        return "$retval"
    }

    function eget.deploy {
        go.init || return $?
        if [ ! -x "$GO_BIN" ]; then
            fail $0 "go '$GO_BIN' isn't found"
            return 1
        elif [ ! -x "$commands[eget]" ]; then
            fail $0 "eget isn't found, try reinstall: go.deploy eget"
            return 1
        fi

        local retval=0
        local packages="$*"
        for pkg in "${(@u)${(z)packages}}"; do
            eget "$pkg" --to "$GOPATH/bin"
            if [ "$?" -gt 0 ]; then
                local retval=1
            fi
        done
        return "$retval"
    }

    function go.install {
        go.deploy $@
        return "$?"
    }

    function go.extras {
        go.deploy $GO_REQ_PACKAGES $GO_REC_PACKAGES
        eget.deploy $EGET_REQ_PACKAGES
        return "$?"
    }

    function go.update {
        go.init || return "$?"

        if [ ! -x "$GO_BIN" ]; then
            fail $0 "go exe $GO_BIN isn't found!"
            return 1
        fi

        local update_exe="$GOPATH/bin/go-global-update"
        if [ ! -x "$update_exe" ]; then
            warn $0 "go update executable $update_exe isn't found!"
            go.extras || return 1
        fi
        run.show "$update_exe"

        local update_exe="$GOPATH/bin/gup"
        if [ ! -x "$update_exe" ]; then
            warn $0 "go update executable $update_exe isn't found!"
            go.extras || return 1
        fi

        run.show "$update_exe update"
        return "$?"
    }
fi
