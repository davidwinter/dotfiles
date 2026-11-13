# Migration: pull the dotfiles repo over HTTPS
#
# dotfiles-update and the daily update check fetch from origin. Over SSH that
# needs your key, which can mean a 1Password prompt just from opening a
# terminal. The repo is public, so fetch over HTTPS instead; pushes still go
# over SSH through the pushInsteadOf rule in .gitconfig. New installs already
# clone over HTTPS.
#
# Only switches the exact SSH address of this repo, and only when the
# pushInsteadOf rule is in effect, so pushing keeps working.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ssh_url="git@github.com:davidwinter/dotfiles"
https_url="https://github.com/davidwinter/dotfiles.git"

current="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"

if [[ "$current" != "$ssh_url" && "$current" != "$ssh_url.git" ]]; then
    echo "  origin is ${current:-not set} - nothing to do"
    exit 0
fi

git -C "$DOTFILES_DIR" remote set-url origin "$https_url"

if [[ "$(git -C "$DOTFILES_DIR" remote get-url --push origin)" != git@github.com:* ]]; then
    git -C "$DOTFILES_DIR" remote set-url origin "$current"
    echo "  ⚠️  Left origin on SSH: pushes would go over HTTPS without the pushInsteadOf rule in ~/.gitconfig" >&2
    exit 0
fi

echo "  ✅ origin now pulls over HTTPS (pushes still use SSH)"
