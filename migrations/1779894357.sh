# Migration: Stow mise config package

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Stowing mise config..."

stow --dir="$DOTFILES_DIR/configs" --target="$HOME" mise
