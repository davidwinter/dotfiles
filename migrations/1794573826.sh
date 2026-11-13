# Migration: remove the Caps Lock to Escape login item
#
# A short-lived version of the mise config installed a LaunchAgent,
# dev.mise.caps-lock-escape, that ran hidutil at login to map Caps Lock to
# Escape. That's now set by hand per keyboard in System Settings (see
# README.md), so unload and delete the agent wherever it was installed, and
# clear the mapping it set for this login session. Mappings set in System
# Settings → Modifier Keys are stored separately and aren't affected.

plist="$HOME/Library/LaunchAgents/dev.mise.caps-lock-escape.plist"

if [[ "$(uname -s)" != "Darwin" ]] || [[ ! -f "$plist" ]]; then
    echo "  No Caps Lock login item installed - nothing to do"
    exit 0
fi

launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
rm -f "$plist"
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' >/dev/null

echo "  ✅ Removed the Caps Lock to Escape login item"
