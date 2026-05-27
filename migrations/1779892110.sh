# Migration: restow scripts package to ensure all dotfiles-* helpers are symlinked
#
# New scripts added to scripts/.local/bin/ require a stow re-run to appear in
# ~/.local/bin. Without this, existing installs miss newly added helpers.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Restowing scripts package..."

if stow --dir="$DOTFILES_DIR" --target="$HOME" --restow scripts; then
    echo "  ✅ Scripts restowed — all dotfiles-* helpers are now symlinked"
else
    echo "  ⚠️  Failed to restow scripts" >&2
    exit 1
fi

echo "✅ Migration complete"
