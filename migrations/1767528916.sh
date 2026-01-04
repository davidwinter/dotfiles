# Migration: Remove ghostty directory symlink and restow ghostty-macOS config

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Checking for ghostty directory symlink on macOS..."

# Only run on macOS
if ! dotfiles-is-macos; then
    echo "  ⏭️  Skipping (not macOS)"
    exit 0
fi

# Remove the ghostty directory if it's a symlink
if [[ -L "$HOME/Library/Application Support/com.mitchellh.ghostty" ]]; then
    rm "$HOME/Library/Application Support/com.mitchellh.ghostty"
    echo "  ✅ Removed ghostty directory symlink"
fi

echo "Re-stowing ghostty-macOS config..."

# Restow ghostty-macOS config from configs directory
if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" --restow ghostty-macOS 2>/dev/null; then
    echo "  ✅ Re-stowed ghostty-macOS config"
else
    echo "  ⚠️  Failed to re-stow ghostty-macOS config" >&2
fi

echo "✅ Migration complete"
