#!/usr/bin/env bash

set -euo pipefail

REPO_URL="davidwinter/dotfiles"
DEST="$HOME/dotfiles"

if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed. Install instructions:"
    uname_s="$(uname -s)"
    if [ "$uname_s" = "Darwin" ]; then
        echo "macOS:"
        echo "  brew install git"
    else
        . /etc/os-release 2>/dev/null || true
        case "${ID:-}" in
            ubuntu|debian)
                echo "Ubuntu/Debian:"
                echo "  sudo apt update && sudo apt install -y git"
                ;;
            arch)
                echo "Arch Linux:"
                echo "  sudo pacman -Syu git"
                ;;
            *)
                echo "Linux (unknown distro): install git with your package manager (apt, dnf, pacman, etc.)"
                ;;
        esac
    fi
    exit 1
fi

AGENT_SOCKET="$HOME/.1password/agent.sock"
if [ ! -S "$AGENT_SOCKET" ]; then
    echo "1Password agent socket not found at: $AGENT_SOCKET"
    if [ "$(uname -s)" = "Darwin" ]; then
        SRC="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        echo "On macOS you can create the symlink recommended by 1Password:"
        echo "  ln -s \"$SRC\" \"$AGENT_SOCKET\""
        read -r -p "Create the symlink now? [y/N] " reply
        case "$reply" in
            [Yy]*)
                if [ ! -e "$SRC" ]; then
                    echo "Source socket not found: $SRC"
                    echo "Ensure 1Password is running and the socket exists, then retry."
                    exit 1
                fi
                mkdir -p "$(dirname "$AGENT_SOCKET")"
                ln -sf "$SRC" "$AGENT_SOCKET"
                echo "Created symlink: $AGENT_SOCKET -> $SRC"
                ;;
            *)
                echo "Skipping symlink creation."
                ;;
        esac
    else
        echo "Ensure the 1Password agent is running and the socket exists at $AGENT_SOCKET (or create an appropriate symlink)."
    fi
fi

echo "Cloning $REPO_URL -> $DEST"
if [ -e "$DEST" ]; then
    echo "Destination already exists: $DEST"
    read -r -p "Remove and re-clone? [y/N] " rem
    case "$rem" in
        [Yy]*)
            rm -rf "$DEST"
            ;;
        *)
            echo "Aborting clone."
            exit 1
            ;;
    esac
fi

SSH_AUTH_SOCK=~/.1password/agent.sock git clone "git@github.com:$REPO_URL.git" "$DEST"
echo "Clone complete: $DEST"