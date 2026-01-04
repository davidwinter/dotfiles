#!/usr/bin/env bash
# Shared library for dotfiles install and doctor scripts

# === Utilities ===

elevate_priv() {
    if ! dotfiles-has-command sudo; then
        echo "sudo not found" >&2
        exit 1
    fi

    if ! sudo -v; then
        echo "Superuser not granted, aborting installation" >&2
        exit 1
    fi
}

# === Package Management ===

check_package_installed() {
    local pkg="$1"

    if dotfiles-is-macos; then
        brew list "$pkg" &>/dev/null || dotfiles-has-command "$pkg"
    elif dotfiles-is-linux; then
        if dotfiles-is-ubuntu; then
            dpkg -s "$pkg" &>/dev/null || dotfiles-has-command "$pkg"
        elif dotfiles-is-archlinux; then
            pacman -Q "$pkg" &>/dev/null || dotfiles-has-command "$pkg"
        fi
    fi
}

ensure_package_installed() {
    local pkg="$1"

    # Return if already installed
    check_package_installed "$pkg" && return 0

    if dotfiles-is-macos; then
        brew install "$pkg"
    elif dotfiles-is-linux; then
        elevate_priv

        if dotfiles-is-ubuntu; then
            sudo apt update && sudo apt install -y "$pkg"
        elif dotfiles-is-archlinux; then
            sudo pacman -Syu "$pkg"
        fi
    fi
}

# === Dotfiles Configurations ===

check_dotfiles_config_present() {
    local pkg="$1"
    local config_dir="${2:-configs}"

    # Check if package directory exists
    local pkg_dir="$DOTFILES_DIR/$config_dir/$pkg"
    [[ ! -d "$pkg_dir" ]] && return 1

    # Find first file in package and check if it exists in HOME
    local first_file=$(find "$pkg_dir" -type f -print -quit)
    [[ -z "$first_file" ]] && return 1

    local rel_path="${first_file#$pkg_dir/}"
    [[ -e "$HOME/$rel_path" ]] || [[ -L "$HOME/$rel_path" ]]
}

ensure_dotfiles_config_present() {
    local pkg="$1"
    local config_dir="${2:-configs}"

    stow --dir="$DOTFILES_DIR/$config_dir" --target="$HOME" "$pkg"
}

# === 1Password ===

check_1password_agent() {
    local socket="${1:-$HOME/.1password/agent.sock}"
    [[ -S "$socket" ]]
}

ensure_1password_agent() {
    local socket="${1:-$HOME/.1password/agent.sock}"

    # Return if already configured
    check_1password_agent "$socket" && return 0

    if dotfiles-is-macos; then
        ln -s "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" "$socket"
        return 0
    fi

    echo "Ensure the 1Password agent is running and the socket exists at $socket (or create an appropriate symlink)."
    exit 1
}

check_1password_ssh_sign() {
    local target="${1:-/usr/local/bin/op-ssh-sign}"
    [[ -x "$target" ]]
}

ensure_1password_ssh_sign() {
    local target="${1:-/usr/local/bin/op-ssh-sign}"

    # Return if already configured
    check_1password_ssh_sign "$target" && return 0

    elevate_priv

    if dotfiles-is-macos; then
        sudo ln -s "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" "$target"
    fi

    if dotfiles-is-linux; then
        if dotfiles-is-wsl; then
            local win_home=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
            sudo ln -s "$win_home/AppData/Local/1Password/app/8/op-ssh-sign-wsl" "$target"
        else
            sudo ln -s "/opt/1Password/op-ssh-sign" "$target"
        fi
    fi
}

# === Git ===

check_git_remote_ssh() {
    cd "$DOTFILES_DIR"

    local current_remote=$(git remote get-url origin 2>/dev/null)
    [[ "$current_remote" =~ ^git@github\.com: ]]
}

ensure_git_remote_ssh() {
    cd "$DOTFILES_DIR"

    # Return if already SSH
    check_git_remote_ssh && return 0

    local current_remote=$(git remote get-url origin)

    if [[ "$current_remote" =~ ^https://github\.com/(.+)$ ]]; then
        local repo="${BASH_REMATCH[1]}"
        repo="${repo%.git}"
        local ssh_url="git@github.com:${repo}.git"

        git remote set-url origin "$ssh_url"
    fi
}

# === Fish Shell ===

check_fish_in_etc_shells() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"
    [[ -n "$fish_path" ]] && grep -Fxq "$fish_path" /etc/shells 2>/dev/null
}

ensure_fish_in_etc_shells() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"

    # Return if already in /etc/shells
    check_fish_in_etc_shells "$fish_path" && return 0

    elevate_priv

    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
}

check_fish_is_default_shell() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"
    local current_shell="${SHELL:-$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || true)}"

    [[ "$current_shell" == "$fish_path" ]]
}

ensure_fish_is_default_shell() {
    local fish_path="${1:-$(command -v fish 2>/dev/null || true)}"

    # Return if already default
    check_fish_is_default_shell "$fish_path" && return 0

    chsh -s "$fish_path"
}

# === Migrations ===

check_migrations_applied() {
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/migrations"

    [[ ! -d "$DOTFILES_DIR/migrations" ]] && return 0

    for migration in "$DOTFILES_DIR/migrations"/*.sh; do
        [[ -f "$migration" ]] || continue
        local migration_file=$(basename "$migration")
        if [[ ! -f "$state_dir/$migration_file" && ! -f "$state_dir/skipped/$migration_file" ]]; then
            return 1
        fi
    done

    return 0
}
