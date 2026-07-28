# Migration: stop stow tree-folding ~/.local/bin and ~/.local/lib
#
# stow folds a directory that only one package owns into a single directory
# symlink (e.g. ~/.local/bin -> ../dotfiles/scripts/.local/bin). That monopolises
# the directory, so a second package (git-1password, which ships git-ssh-sign)
# cannot add its own file there. Unfold those directories into real directories
# of per-file symlinks by re-stowing with --no-folding, so any package can
# contribute to them.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Replace tree-folded directory symlinks with real directories. Only touch a path
# that is a symlink pointing back into the repo, so we never remove an unrelated
# directory or symlink a user created themselves.
for dir in "$HOME/.local/bin" "$HOME/.local/lib"; do
    if [[ -L "$dir" ]] && [[ "$(realpath "$dir" 2>/dev/null)" == "$DOTFILES_DIR"* ]]; then
        echo "  Unfolding $dir (was a directory symlink)"
        rm "$dir"
    fi
done

echo "Re-stowing scripts with --no-folding..."
if stow --restow --no-folding --dir="$DOTFILES_DIR" --target="$HOME" scripts; then
    echo "  ✅ scripts re-stowed as per-file symlinks"
else
    echo "  ⚠️  Failed to re-stow scripts" >&2
fi

# Re-stow git-1password only where it is already installed (desktop machines).
# Key off the include symlink so this stays correct even when run over SSH, and
# leave headless/remote installs (which never had the package) untouched.
include="$HOME/.config/git/config-1password"
if [[ -L "$include" ]] && [[ "$(realpath "$include" 2>/dev/null)" == "$DOTFILES_DIR"* ]]; then
    echo "Re-stowing git-1password with --no-folding..."
    if stow --restow --no-folding --dir="$DOTFILES_DIR/configs" --target="$HOME" git-1password; then
        echo "  ✅ git-1password re-stowed (git-ssh-sign wrapper linked)"
    else
        echo "  ⚠️  Failed to re-stow git-1password" >&2
    fi
else
    echo "  ℹ️  git-1password not stowed here — skipping"
fi

echo "✅ Migration complete"
