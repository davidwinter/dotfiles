# Migration: Stow omarchy hypr bindings.conf config

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Only run on Arch Linux (omarchy)
if ! dotfiles-is-arch; then
    echo "  ⏭️  Skipping (not Arch Linux)"
    exit 0
fi

# Exit early if the symlink already exists
if [[ -L "$HOME/.config/hypr/bindings.conf" ]]; then
    echo "  ⏭️  bindings.conf symlink already exists, skipping"
    exit 0
fi

echo "Checking for conflicting bindings.conf..."

# Remove any existing regular file that would conflict
if [[ -e "$HOME/.config/hypr/bindings.conf" ]]; then
    rm "$HOME/.config/hypr/bindings.conf"
    echo "  ✅ Removed existing bindings.conf"
fi

echo "Creating bindings.conf symlink..."

if ln -sf "$DOTFILES_DIR/configs/omarchy/.config/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"; then
    echo "  ✅ Symlinked bindings.conf"
else
    echo "  ⚠️  Failed to symlink bindings.conf" >&2
fi

# Reload Hyprland config if it is currently running
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "Reloading Hyprland config..."
    if hyprctl reload; then
        echo "  ✅ Hyprland config reloaded"
    else
        echo "  ⚠️  Failed to reload Hyprland config" >&2
    fi
fi

echo "✅ Migration complete"
