# Migration: make way for the dotfiles' Omarchy 4 Hyprland files
#
# Omarchy 4 reads Hyprland overrides from ~/.config/hypr/bindings.lua and
# autostart.lua, which it creates as plain files (on upgrade, from the old
# .conf overrides). The dotfiles now link both, and mise won't replace a plain
# file, so move each aside first. Their settings are now in the dotfiles
# (configs/omarchy/.config/hypr). Files that are already links are left alone.

if ! command -v omarchy-version >/dev/null 2>&1; then
    echo "  Not Omarchy - nothing to do"
    exit 0
fi

stamp="$(date +%Y%m%d%H%M%S)"
moved=0
for name in bindings.lua autostart.lua; do
    file="$HOME/.config/hypr/$name"
    if [[ -f "$file" && ! -L "$file" ]]; then
        mv "$file" "$file.bak.$stamp"
        echo "  ✅ Moved ~/.config/hypr/$name aside to $name.bak.$stamp"
        moved=1
    fi
done

if [[ "$moved" == 0 ]]; then
    echo "  No plain Hyprland Lua files to move - nothing to do"
fi
