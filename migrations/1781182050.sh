# Migration: stow zed config package

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

ZED_SETTINGS="$HOME/.config/zed/settings.json"

if [[ -f "$ZED_SETTINGS" && ! -L "$ZED_SETTINGS" ]]; then
    backup="${ZED_SETTINGS}.bak.$(date +%s)"
    mv "$ZED_SETTINGS" "$backup"
    echo "  ✅ Backed up existing zed settings.json to $backup"
fi

echo "Stowing zed config..."

if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" zed; then
    echo "  ✅ Stowed zed config"
else
    echo "  ⚠️  Failed to stow zed config" >&2
    exit 1
fi

echo "✅ Migration complete"
