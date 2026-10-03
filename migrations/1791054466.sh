# Migration: adopt the tracked ~/.claude/settings.json
#
# settings.json is now part of the claude package (alongside CLAUDE.md,
# principles.md, agents/, lenses/), but dotfiles-update only runs
# `git pull` + migrations — it never re-runs the stow conflict-check that
# ensure_dotfiles_config_present does on a fresh install. Every existing
# machine still has a real, unmanaged ~/.claude/settings.json that stow
# will refuse to overwrite.
#
# Back up any existing file (it may carry machine-specific tweaks worth
# reviewing — there's no local-override mechanism for this file yet, see
# AI.md) and re-stow so the tracked version takes over.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
target="$HOME/.claude/settings.json"

if [[ -L "$target" ]] && [[ "$(realpath "$target" 2>/dev/null)" == "$DOTFILES_DIR"* ]]; then
    echo "  ~/.claude/settings.json already tracked — skipping"
    exit 0
fi

if [[ -e "$target" ]]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "  Backed up existing ~/.claude/settings.json to $backup"
fi

echo "Stowing claude package..."
if stow --restow --no-folding --dir="$DOTFILES_DIR/configs" --target="$HOME" claude; then
    echo "  ✅ ~/.claude/settings.json now tracked"
else
    echo "  ⚠️  Failed to stow claude package" >&2
    exit 1
fi

echo "✅ Migration complete"
