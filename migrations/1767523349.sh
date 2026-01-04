# Migration: Remove fish functions directory symlink and restow fish config

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Checking for fish functions directory symlink..."

# Remove the functions directory if it's a symlink
if [[ -L "$HOME/.config/fish/functions" ]]; then
    rm "$HOME/.config/fish/functions"
    echo "  ✅ Removed fish functions directory symlink"
fi

echo "Re-stowing fish config..."

# Restow fish config from configs directory
if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" --restow fish 2>/dev/null; then
    echo "  ✅ Re-stowed fish config"
else
    echo "  ⚠️  Failed to re-stow fish config" >&2
fi

echo "✅ Migration complete"
