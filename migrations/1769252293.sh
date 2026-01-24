# Migration: remove old dotfiles-is-archlinux symlink and re-stow scripts

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
OLD_SYMLINK="$HOME/.local/bin/dotfiles-is-archlinux"

# Remove the dotfiles-is-archlinux if it's a symlink
if [[ -L "$OLD_SYMLINK" ]]; then
    rm "$OLD_SYMLINK"
    echo "  ✅ Removed old dotfiles-is-archlinux symlink"
fi

echo "Re-stowing scripts config..."

# Restow scripts config from configs directory
if stow --dir="$DOTFILES_DIR" --target="$HOME" --restow scripts 2>/dev/null; then
    echo "  ✅ Re-stowed scripts config"
else
    echo "  ⚠️  Failed to re-stow scripts config" >&2
fi

echo "✅ Migration complete"
