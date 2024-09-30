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

logged_in="$(gh auth status --active | grep 'Logged in' | wc -l)"

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
