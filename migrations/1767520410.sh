DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "Removing old symlinks..."

remove_symlink() {
    if [[ -L "$1" ]]; then
        rm "$1"
    fi
}

remove_symlink "$HOME/.local/bin/dotfiles-install"
remove_symlink "$HOME/.local/bin/dotfiles-update"
remove_symlink "$HOME/.local/bin/dotfiles-check-updates"
remove_symlink "$HOME/.local/bin/dotfiles-updates-notify"
remove_symlink "$HOME/.local/bin/dotfiles-add-migration"
remove_symlink "$HOME/.local/bin/dotfiles-migrate"
remove_symlink "$HOME/.local/bin/dotfiles-migrations-status"
remove_symlink "$HOME/.local/bin/dotfiles-is-macos"
remove_symlink "$HOME/.local/bin/dotfiles-is-linux"
remove_symlink "$HOME/.local/bin/dotfiles-is-wsl"
remove_symlink "$HOME/.local/bin/dotfiles-is-ubuntu"
remove_symlink "$HOME/.local/bin/dotfiles-is-archlinux"
remove_symlink "$HOME/.local/bin/dotfiles-has-command"
remove_symlink "$HOME/.local/bin/dotfiles-detect-linux-distro"
remove_symlink "$HOME/.ssh/config"
remove_symlink "$HOME/.gitconfig"
remove_symlink "$HOME/.config/git/config-wsl"
remove_symlink "$HOME/.config/fish/config.fish"
remove_symlink "$HOME/.config/starship.toml"
remove_symlink "$HOME/.hushlogin"
remove_symlink "$HOME/.nanorc"
remove_symlink "$HOME/.vimrc"
remove_symlink "$HOME/.config/ghostty/config"
remove_symlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
remove_symlink "$HOME/.config/hypr/autostart.conf"
remove_symlink "$HOME/.config/waybar/config.jsonc"
remove_symlink "$HOME/.config/fish/functions/ls.fish"
remove_symlink "$HOME/.config/fish/functions/serve.fish"

echo "  ✅ Removed old symlinks"

cd "$DOTFILES_DIR"

echo
echo "Stowing scripts from root directory..."

# Stow the renamed scripts directory (was local-bin, now scripts)
if stow --dir="$DOTFILES_DIR" --target="$HOME" scripts 2>/dev/null; then
    echo "  ✅ Stowed scripts from root"
else
    echo "  ⚠️  Failed to stow scripts (may already exist)" >&2
fi

echo
echo "Stowing packages from configs/ directory..."

# Helper function using newly stowed scripts
stow_package() {
    local pkg="$1"
    if stow --dir="$DOTFILES_DIR/configs" --target="$HOME" "$pkg" 2>/dev/null; then
        echo "  ✅ Stowed $pkg from configs/"
    else
        echo "  ⚠️  Failed to stow $pkg (may already exist)" >&2
    fi
}

# List of packages now in configs/ directory
NEW_PACKAGES=(fish git starship ssh hushlogin nano vim)

for pkg in "${NEW_PACKAGES[@]}"; do
    stow_package "$pkg"
done

# Handle platform-specific packages using helper scripts
dotfiles-is-macos && stow_package ghostty-macOS
dotfiles-is-archlinux && stow_package omarchy
dotfiles-is-wsl && stow_package git-wsl

echo
echo "✅ Migration complete - all packages now stowed from configs/, scripts at root"
