# Playbook

https://xcfile.dev/

## github-copilot-deploy

interactive: true

```zsh
binary="$(which gh)"
if [ ! -x "$binary" ]; then
    brew install gh
fi

#

logged_in="$(gh auth status --active | grep 'Logged in')"
logged_in="$(printf "$logged_in" | wc -l)"

if [ "$logged_in" -eq 0 ]; then
    gh auth login
fi

#

installed="$(gh extension list | grep gh-copilot | wc -l)"

if [ "$logged_in" -eq 0 ]; then
    gh extension install github/gh-copilot
else
    gh extension upgrade gh-copilot
fi

```


## golang-install-latest

https://go.dev/dl/

interactive: true

```zsh
go install golang.org/dl/go1.10.7@latest
go install github.com/Gelio/go-global-update@latest
go-global-update

```
