source "$(dirname "$0")/init.sh"
depr "$0" "update ~/.zshrc, boot.sh deprecated"

if [ -d "$ASH" ]; then
    source "$ASH/run/units/configs.sh"
    ASH_FORCE_CONFIGS=1 cfg.copy "$ASH/.zshrc" "$HOME/.zshrc"
fi
