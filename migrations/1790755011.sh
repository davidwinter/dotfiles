# Migration: fix git-ssh-sign missing from ~/.local/bin
#
# Migration 1785260700 re-stowed git-1password only when config-1password was
# already a direct file symlink into the dotfiles. On some machines it is a
# regular file (or accessed through a stow-folded directory symlink), so that
# guard silently skipped the re-stow, leaving git-ssh-sign unlinked.
#
# This migration widens the check: if config-1password ultimately resolves into
# the dotfiles tree (direct symlink OR folded directory symlink) treat it as
# "git-1password is intended here" and re-stow with --no-folding so both
# config-1password and git-ssh-sign land as proper per-file symlinks.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

git_ssh_sign="$HOME/.local/bin/git-ssh-sign"
include="$HOME/.config/git/config-1password"
repo_include="$DOTFILES_DIR/configs/git-1password/.config/git/config-1password"

# Already correct — both files are directly symlinked, nothing to do.
if [[ -L "$git_ssh_sign" ]] && [[ "$(realpath "$git_ssh_sign" 2>/dev/null)" == "$DOTFILES_DIR"* ]] && \
   [[ -L "$include" ]] && [[ "$(realpath "$include" 2>/dev/null)" == "$DOTFILES_DIR"* ]]; then
    echo "  git-ssh-sign and config-1password already symlinked — skipping"
    exit 0
fi

# Determine whether git-1password is intended on this machine.
# Use realpath so a stow-folded directory symlink (where the file appears as a
# regular file but actually lives inside the dotfiles tree) is handled correctly.
# Never rm the file in this branch — stow --restow --no-folding will unfold the
# directory and replace the path with a proper per-file symlink.
intended=false
realpath_include="$(realpath "$include" 2>/dev/null)"
if [[ -n "$realpath_include" ]] && [[ "$realpath_include" == "$DOTFILES_DIR"* ]]; then
    # File resolves into the dotfiles tree (direct symlink or folded dir).
    intended=true
elif [[ -f "$include" ]] && [[ ! -L "$include" ]] && diff -q "$include" "$repo_include" &>/dev/null; then
    # True orphan: a real file in a real directory, content matches the repo.
    # Safe to remove so stow can place its own symlink.
    echo "  config-1password is an unmanaged file with matching content — removing so stow can link it"
    rm "$include"
    intended=true
fi

if [[ "$intended" == false ]]; then
    echo "  git-1password not intended on this machine — skipping"
    exit 0
fi

# Ensure ~/.local/bin is a real directory so per-file symlinks can land.
bin_dir="$HOME/.local/bin"
if [[ -L "$bin_dir" ]] && [[ "$(realpath "$bin_dir" 2>/dev/null)" == "$DOTFILES_DIR"* ]]; then
    echo "  Unfolding $bin_dir (was a directory symlink)"
    rm "$bin_dir"
fi

echo "Re-stowing git-1password with --no-folding..."
if stow --restow --no-folding --dir="$DOTFILES_DIR/configs" --target="$HOME" git-1password; then
    echo "  ✅ git-1password re-stowed (git-ssh-sign and config-1password linked)"
else
    echo "  ⚠️  Failed to re-stow git-1password" >&2
    exit 1
fi

echo "✅ Migration complete"
