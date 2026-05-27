# Migration: stow claude config package to create ~/.claude/CLAUDE.md

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Stowing claude config..."

if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" claude; then
    echo "  ✅ Stowed claude config — ~/.claude/CLAUDE.md is now active"
else
    echo "  ⚠️  Failed to stow claude config" >&2
    exit 1
fi

echo "✅ Migration complete"
