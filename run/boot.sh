source "$(dirname "$0")/init.sh"

if [[ "$ASH" =~ '/.josh/custom/plugins/josh$' ]] || [ ! -d "$HOME/.oh-my-zsh" ]; then
    fail "$0" "running Ash in old Josh context, force redeploy"

    if [ ! -d "$HOME/.ash" ] && [ -d "$HOME/.josh/custom/plugins/josh" ]; then
        mv "$HOME/.josh/custom/plugins/josh" "$HOME/.ash"
        ln -s "$HOME/.ash" "$HOME/.josh/custom/plugins/josh"
    fi
    INSTALL=1 zsh "$HOME/.ash/run/init.sh"

elif [ -d "$ASH" ]; then
    depr "$0" "update ~/.zshrc, boot.sh deprecated"

    source "$ASH/run/units/configs.sh"
    ASH_FORCE_CONFIGS=1 cfg.copy "$ASH/.zshrc" "$HOME/.zshrc"
fi
