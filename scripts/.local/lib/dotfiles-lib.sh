#!/usr/bin/env bash
# Shared library for dotfiles install and doctor scripts

# === Configuration ===

DOTFILES_CONFIG="${DOTFILES_DIR:-$HOME/dotfiles}/dotfiles.json"
CORE_PACKAGES_FILE="${DOTFILES_DIR:-$HOME/dotfiles}/system/core-packages.json"

get_current_platform() {
    if dotfiles-is-macos; then
        echo "macos"
    elif dotfiles-is-linux; then
        local distro=$(dotfiles-detect-linux-distro)
        echo "${distro:-linux}"
    else
        echo "unknown"
    fi
}

get_current_traits() {
    if ! dotfiles-is-ssh-session; then
        echo "desktop"
    fi
    if dotfiles-is-wsl; then
        echo "wsl"
    fi
}

get_current_traits_json() {
    get_current_traits | jq -Rn '[inputs | select(length > 0)]'
}

# === Core packages helpers ===
# Read core packages defined for the dotfiles system (git, stow, curl, jq, etc.)
get_core_packages() {
    if [[ -f "$CORE_PACKAGES_FILE" ]]; then
        jq -r '.packages[]' "$CORE_PACKAGES_FILE" 2>/dev/null || true
    fi
}

# Check if a package is considered a core package
# Usage: is_core_package <pkgname>
is_core_package() {
    local target="$1"
    if [[ -z "$target" ]]; then
        return 1
    fi

    # Read through core packages and compare
    local cp
    while IFS= read -r cp; do
        [[ -z "$cp" ]] && continue
        if [[ "$cp" == "$target" ]]; then
            return 0
        fi
    done < <(get_core_packages)

    return 1
}

# Install core packages defined in system/core-packages.json
# Returns non-zero on first failure
install_core_packages() {
    local pkg
    if [[ -f "$CORE_PACKAGES_FILE" ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            if ! ensure_package_installed "$pkg"; then
                echo "   ⚠️  Failed to install core package: $pkg" >&2
                return 1
            fi
        done < <(get_core_packages)
    fi
    return 0
}

# Check core packages and print status lines (used by dotfiles-doctor)
check_core_packages() {
    local pkg
    if [[ -f "$CORE_PACKAGES_FILE" ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            if check_package_installed "$pkg"; then
                echo "   ✅ $pkg"
            else
                echo "   ❌ $pkg"
            fi
        done < <(get_core_packages)
    else
        echo "   ℹ️  No core packages definition found at $CORE_PACKAGES_FILE"
    fi
}

# Get packages from config that apply to current host (platform + traits)
get_packages_for_host() {
    local platform=$(get_current_platform)
    local host_traits=$(get_current_traits_json)

    jq -r --arg platform "$platform" --argjson host_traits "$host_traits" '
        .packages[]
        | if type == "string" then
            .
        elif type == "object" then
            if (.traits != null and ((.traits | map(select(. as $t | $host_traits | index($t))) | length) == 0)) then
                empty
            elif .platforms then
                if (.platforms | type) == "array" then
                    # Array format: check if platform is in list
                    if (.platforms | map(select(. == $platform or . == "linux")) | length) > 0 then
                        .name
                    else empty end
                elif (.platforms | type) == "object" then
                    # Object format: get platform-specific package name
                    if .platforms[$platform] then
                        .platforms[$platform]
                    elif .platforms["linux"] and ($platform != "macos") then
                        .platforms["linux"]
                    else empty end
                else empty end
            else
                # No platform restriction
                .name
            end
        else empty end
    ' "$DOTFILES_CONFIG"
}

# Get configs from config that apply to current host (platform + traits)
# Always includes 'scripts' config first
get_configs_for_host() {
    local platform=$(get_current_platform)
    local host_traits=$(get_current_traits_json)

    # Always output scripts first
    echo "scripts"

    # Then output configs from JSON
    jq -r --arg platform "$platform" --argjson host_traits "$host_traits" '
        .configs[]
        | if type == "string" then
            .
        elif type == "object" then
            if (.traits != null and ((.traits | map(select(. as $t | $host_traits | index($t))) | length) == 0)) then
                empty
            elif .platforms then
                # Check if platform is in the list
                if (.platforms | map(select(. == $platform or . == "linux")) | length) > 0 then
                    .name
                else empty end
            else
                # No platform restriction
                .name
            end
        else empty end
    ' "$DOTFILES_CONFIG"
}

# Get all packages (for validation/listing)
get_all_packages() {
    jq -r '
        .packages[]
        | if type == "string" then
            .
        elif type == "object" then
            .name
        else empty end
    ' "$DOTFILES_CONFIG"
}

# Get all configs (for validation/listing)
get_all_configs() {
    # Always include scripts
    echo "scripts"

    jq -r '
        .configs[]
        | if type == "string" then
            .
        elif type == "object" then
            .name
        else empty end
    ' "$DOTFILES_CONFIG"
}

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
        elif dotfiles-is-arch; then
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
        elif dotfiles-is-arch; then
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

    echo "   ⚠️  Ensure the 1Password agent is running and the socket exists at $socket (or create an appropriate symlink)." >&2
    return 1
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
    local current_shell

    if dotfiles-is-macos; then
        current_shell=$(dscl . -read "/Users/$(whoami)" UserShell 2>/dev/null | awk '{print $2}' || true)
    else
        current_shell=$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || true)
    fi

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
