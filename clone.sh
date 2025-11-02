#!/usr/bin/env bash

set -euo pipefail

REPO_URL="davidwinter/dotfiles"
DEST="$HOME/dotfiles"
AGENT_SOCKET="$HOME/.1password/agent.sock"
OP_SSH_SIGN_DEST="/usr/local/bin/op-ssh-sign"

ensure_installed() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    echo "$cmd is not installed. Install instructions:"
    local uname_s
    uname_s="$(uname -s)"
    if [ "$uname_s" = "Darwin" ]; then
        echo "macOS:"
        echo "  brew install $pkg"
    else
        . /etc/os-release 2>/dev/null || true
        case "${ID:-}" in
            ubuntu|debian)
                echo "Ubuntu/Debian:"
                echo "  sudo apt update && sudo apt install -y $pkg"
                ;;
            arch)
                echo "Arch Linux:"
                echo "  sudo pacman -Syu $pkg"
                ;;
            *)
                echo "Linux (unknown distro): install $pkg with your package manager (apt, dnf, pacman, etc.)"
                ;;
        esac
    fi
    exit 1
}

ensure_1password_agent() {
    local socket="${1:-$AGENT_SOCKET}"

    if [ -S "$socket" ]; then
        return 0
    fi

    echo "1Password agent socket not found at: $socket"
    if [ "$(uname -s)" = "Darwin" ]; then
        local src="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        echo "On macOS you can create the symlink recommended by 1Password:"
        echo "  ln -s \"$src\" \"$socket\""
        read -r -p "Create the symlink now? [y/N] " reply
        case "$reply" in
            [Yy]*)
                if [ ! -e "$src" ]; then
                    echo "Source socket not found: $src"
                    echo "Ensure 1Password is running and the socket exists, then retry."
                    exit 1
                fi
                mkdir -p "$(dirname "$socket")"
                ln -sf "$src" "$socket"
                echo "Created symlink: $socket -> $src"
                return 0
                ;;
            *)
                echo "Skipping symlink creation."
                ;;
        esac
    fi

    echo "Ensure the 1Password agent is running and the socket exists at $socket (or create an appropriate symlink)."
    exit 1
}

clone_repo() {
    local repo="${1:-$REPO_URL}"
    local dest="${2:-$DEST}"
    local agent_socket="${3:-$AGENT_SOCKET}"

    if [ -e "$dest" ]; then
        return 0
    fi

    echo "Cloning $repo -> $dest"

    mkdir -p "$(dirname "$dest")"

    # expand leading ~ if present
    if [ "${agent_socket#~}" != "$agent_socket" ]; then
        agent_socket="${agent_socket/#\~/$HOME}"
    fi

    SSH_AUTH_SOCK="$agent_socket" git clone "git@github.com:$repo.git" "$dest"
    echo "Clone complete: $dest"
}

ensure_1password_ssh_sign() {
    local target="${1:-$OP_SSH_SIGN_DEST}"

    if [ -x "$target" ]; then
        return 0
    fi

    echo "1Password ssh-sign helper not found at: $target"

    local uname_s
    uname_s="$(uname -s)"

    # macOS: offer to symlink from the app bundle path
    if [ "$uname_s" = "Darwin" ]; then
        local src="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        echo "On macOS you can create the symlink recommended by 1Password:"
        echo "  ln -s \"$src\" \"$target\""
        exit 1
    else
        echo "On Linux you can create the symlink to the op-ssh-sign binary installed by 1Password."
        echo "  ln -s /opt/1Password/op-ssh-sign \"$target\""
        exit 1
    fi
}

ensure_fish_in_etc_shells() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"

    if grep -Fxq "$fish_path" /etc/shells; then
        return 0
    fi

    echo "fish binary ($fish_path) is not listed in /etc/shells."
    echo "To add it, run:"
    echo "  printf '%s\n' \"$fish_path\" | sudo tee -a /etc/shells"
    echo "After adding it you can make it your login shell (see next step)."
    exit 1
}

ensure_fish_is_default_shell() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"
    local current_shell="${SHELL:-$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || true)}"

    if [ "$current_shell" = "$fish_path" ]; then
        return 0
    fi

    echo "Your current login shell is: ${current_shell:-unknown}"
    echo "To change your login shell to fish, run:"
    echo "  chsh -s \"$fish_path\""
    echo "Important: log out and log back in (or restart your session/terminal) for the change to take effect."
    exit 1
}

ensure_installed git && echo "✅ git is installed"
ensure_installed stow && echo "✅ stow is installed"
ensure_installed fish && echo "✅ fish is installed"

ensure_1password_agent "$AGENT_SOCKET" && echo "✅ 1Password agent socket OK"

ensure_1password_ssh_sign "$OP_SSH_SIGN_DEST" && echo "✅ 1Password op-ssh-sign helper available at $OP_SSH_SIGN_DEST"

clone_repo && echo "✅ dotfiles repository available at $DEST"

ensure_fish_in_etc_shells && echo "✅ fish is listed in /etc/shells"
ensure_fish_is_default_shell && echo "✅ fish is your default login shell"
