# Migration: make way for the dotfiles' Hyprland input.lua
#
# The dotfiles now link ~/.config/hypr/input.lua (natural trackpad scrolling).
# Omarchy creates it as a plain file, and mise won't replace a plain file, so
# move it aside first. A file that's already a link is left alone.

if ! command -v omarchy-version >/dev/null 2>&1; then
    echo "  Not Omarchy - nothing to do"
    exit 0
fi

file="$HOME/.config/hypr/input.lua"
if [[ -f "$file" && ! -L "$file" ]]; then
    stamp="$(date +%Y%m%d%H%M%S)"
    mv "$file" "$file.bak.$stamp"
    echo "  ✅ Moved ~/.config/hypr/input.lua aside to input.lua.bak.$stamp"
else
    echo "  No plain input.lua to move - nothing to do"
fi
