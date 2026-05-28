# Migration: Stow mise config package

echo "Stowing mise config..."

stow --dir="$DOTFILES_DIR/configs" --target="$HOME" mise
