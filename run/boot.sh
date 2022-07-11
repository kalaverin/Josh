source "$(dirname "$0")/init.sh"
depr "$0" "update ~/.zshrc, boot.sh deprecated"

if [[ "$ASH" =~ '/.josh/custom/plugins/josh$' ]]; then
    fail "$0" "running Ash in old Josh context, force redeploy"
    git clone --branch develop --single-branch 'https://github.com/kalaverin/Josh.git' "$HOME/.ash" && \
    INSTALL=1 zsh "$HOME/.ash/run/init.sh"

elif [ -d "$ASH" ]; then
    source "$ASH/run/units/configs.sh"
    ASH_FORCE_CONFIGS=1 cfg.copy "$ASH/.zshrc" "$HOME/.zshrc"
fi
