# Migration: remove links that mise doesn't create
#
# Mise now links the dotfiles (migration plan phase 3). Machine-specific files
# come from config modules, chosen by what the machine has rather than the old
# platforms and traits, so a few links stow made no longer belong:
#
# - git-1password files where the 1Password app isn't installed (WSL, where
#   config-wsl handles signing, or a desktop without 1Password)
# - omarchy files on Arch machines that aren't running Omarchy
# - the link to dotfiles-validate, which was removed with dotfiles.json
#
# Only links pointing into this repo are removed. Uses plain commands, since
# the dotfiles-* helpers may change in later phases.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

remove_repo_link() {
    local path="$1"
    if [[ -L "$path" ]] && [[ "$(readlink "$path")" == *dotfiles/* ]]; then
        rm "$path"
        echo "  Removed $path"
    fi
}

has_1password=false
if [[ "$(uname -s)" == "Darwin" ]]; then
    [[ -d /Applications/1Password.app ]] && has_1password=true
else
    [[ -x /opt/1Password/1password ]] && has_1password=true
fi

if [[ "$has_1password" == false ]]; then
    remove_repo_link "$HOME/.config/git/config-1password"
    remove_repo_link "$HOME/.local/bin/git-ssh-sign"
fi

is_omarchy=false
if [[ -r /etc/os-release ]] && [[ "$(. /etc/os-release && echo "${ID:-}")" == "omarchy" ]]; then
    is_omarchy=true
fi

if [[ "$is_omarchy" == false ]]; then
    remove_repo_link "$HOME/.config/hypr/bindings.conf"
    remove_repo_link "$HOME/.config/hypr/autostart.conf"
    remove_repo_link "$HOME/.config/waybar/config.jsonc"
fi

remove_repo_link "$HOME/.local/bin/dotfiles-validate"

echo "  ✅ Leftover links checked"
