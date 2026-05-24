# Migration: split op-ssh-sign override into git-1password stow package

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

if dotfiles-is-ssh-session; then
    echo "  ℹ️  SSH session — skipping git-1password stow"
    exit 0
fi

echo "Stowing git-1password config..."

if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" git-1password 2>/dev/null; then
    echo "  ✅ Stowed git-1password config"
else
    echo "  ⚠️  Failed to stow git-1password config" >&2
fi

echo "✅ Migration complete"
