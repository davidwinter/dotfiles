# Migration: restow claude package to pick up agents/, lenses/, principles.md

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Restowing claude config to pick up agents/..."

if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" --restow claude; then
    echo "  ✅ Restowed claude config"
else
    echo "  ⚠️  Failed to restow claude config" >&2
    exit 1
fi

echo "✅ Migration complete"
