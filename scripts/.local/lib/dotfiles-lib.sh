#!/usr/bin/env bash
# Shared library for dotfiles install and doctor scripts

# === Configuration ===

DOTFILES_CONFIG="${DOTFILES_DIR:-$HOME/dotfiles}/dotfiles.json"

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

# === Dotfiles Configurations ===

# Files in a package that stow will actually link. Stow's default ignore list
# skips .gitignore (used in fish and ssh to keep runtime files out of the repo),
# so checking for it in $HOME would always report a false conflict or failure.
list_stowable_files() {
    local dir="$1"; shift
    find "$dir" -type f ! -name '.gitignore' "$@"
}

# Returns 0 if every file in the package is linked into $HOME. Prints each
# target that is missing or doesn't resolve to its file in the repo (handles
# both per-file symlinks and tree-folded directory symlinks).
check_dotfiles_config_present() {
    local pkg="$1"
    local config_dir="${2:-configs}"
    local pkg_dir="$DOTFILES_DIR/$config_dir/$pkg"

    [[ ! -d "$pkg_dir" ]] && return 1

    local file target ok=0 found=0
    while IFS= read -r file; do
        found=1
        target="$HOME/${file#$pkg_dir/}"
        if [[ ! -e "$target" ]] || [[ "$(realpath "$target" 2>/dev/null)" != "$(realpath "$file")" ]]; then
            echo "~/${file#$pkg_dir/}"
            ok=1
        fi
    done < <(list_stowable_files "$pkg_dir")

    [[ $found -eq 1 ]] && return $ok
    return 1
}

ensure_dotfiles_config_present() {
    local pkg="$1"
    local config_dir="${2:-configs}"
    local pkg_dir="$DOTFILES_DIR/$config_dir/$pkg"

    # Check for conflicting files before stowing. A conflict is a file that exists
    # at the target path but does NOT trace back to dotfiles — covers both direct
    # file symlinks and tree-folded directory symlinks that stow creates.
    while IFS= read -r file; do
        local rel_path="${file#$pkg_dir/}"
        local target="$HOME/$rel_path"
        local real_target
        real_target=$(realpath "$target" 2>/dev/null) || true
        if [[ -e "$target" ]] && [[ "$real_target" != "$DOTFILES_DIR"* ]]; then
            echo "   ⚠️  Conflict: $target already exists"
            local choice
            while true; do
                read -r -p "      [b]ackup with timestamp, [d]elete, or [s]kip package? " choice </dev/tty
                case "$choice" in
                    b|B)
                        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
                        mv "$target" "$backup"
                        echo "      Backed up to $backup"
                        break
                        ;;
                    d|D)
                        rm -f "$target"
                        echo "      Deleted $target"
                        break
                        ;;
                    s|S)
                        echo "      Skipping $pkg"
                        return 0
                        ;;
                    *)
                        echo "      Please enter b, d, or s"
                        ;;
                esac
            done
        fi
    done < <(list_stowable_files "$pkg_dir")

    # --no-folding keeps shared directories like ~/.local real, so several
    # packages can contribute files and nothing gets written into the repo.
    stow --no-folding --dir="$DOTFILES_DIR/$config_dir" --target="$HOME" "$pkg"
}

# Re-stow every config that belongs on this host. ensure_dotfiles_config_present
# is idempotent and already handles new files landing in an already-installed
# package, so calling this on every `dotfiles-update` (not just fresh installs)
# means a new file added to an existing package never needs its own migration —
# it gets linked (backing up any conflicting unmanaged file first) the next
# time the user updates.
stow_configs_for_host() {
    local failed=0

    while IFS= read -r config; do
        if [[ "$config" == "scripts" ]]; then
            if ensure_dotfiles_config_present "scripts" "."; then
                echo "   ✅ scripts config enabled"
            else
                echo "   ❌ scripts config failed" >&2
                failed=1
            fi
        else
            if ensure_dotfiles_config_present "$config"; then
                echo "   ✅ $config config enabled"
            else
                echo "   ❌ $config config failed" >&2
                failed=1
            fi
        fi
    done < <(get_configs_for_host)

    return "$failed"
}

# === mise ===

# The oldest mise these dotfiles support. Raise it when the mise config starts
# relying on a newer feature; install and update stop on anything older.
MISE_MIN_VERSION="2026.11.6"

# True when version $1 is at least $2 (both year.month.patch).
version_at_least() {
    local IFS=.
    local -a have=($1) need=($2)
    local i h n
    for i in 0 1 2; do
        h="${have[$i]:-0}"; h="${h%%[!0-9]*}"
        n="${need[$i]:-0}"; n="${n%%[!0-9]*}"
        (( ${h:-0} > ${n:-0} )) && return 0
        (( ${h:-0} < ${n:-0} )) && return 1
    done
    return 0
}

get_mise_version() {
    mise --version 2>/dev/null | awk 'NR==1 { print $1 }'
}

# Checks mise is installed and new enough, explaining what to do if not.
check_mise_ready() {
    if ! dotfiles-has-command mise; then
        echo "   ❌ mise not found - install it from https://mise.jdx.dev (see README.md)" >&2
        return 1
    fi

    local version
    version="$(get_mise_version)"
    if ! version_at_least "$version" "$MISE_MIN_VERSION"; then
        echo "   ❌ mise $version is too old - these dotfiles need $MISE_MIN_VERSION or newer" >&2
        echo "      Update it the way you installed it (e.g. brew upgrade mise, or your package manager)" >&2
        return 1
    fi
}

# Applies the mise config: today the tools, and more of the machine setup as
# docs/mise-migration-plan.md progresses. MISE_ENV selects this machine's
# config modules (see dotfiles-mise-env). Never fails the caller.
apply_mise_bootstrap() {
    if MISE_ENV="$(dotfiles-mise-env)" mise bootstrap --yes; then
        echo "   ✅ mise bootstrap applied"
    else
        echo "   ⚠️  mise bootstrap failed - run it again with: mise bootstrap" >&2
    fi
}

# System packages live in the mise config ([bootstrap.packages]). On a fresh
# install that config isn't linked yet, and stow (which links it) is one of
# the packages, so point mise at the repo's copy for this step.
install_bootstrap_packages() {
    MISE_CONFIG_DIR="${DOTFILES_DIR:-$HOME/dotfiles}/configs/mise/.config/mise" \
        MISE_ENV="$(dotfiles-mise-env)" mise bootstrap --yes --only packages
}

# Prints each declared package's state; returns 1 if any is missing.
check_bootstrap_packages() {
    local status
    status="$(MISE_ENV="$(dotfiles-mise-env)" mise bootstrap packages status 2>&1)" || true
    echo "$status" | grep -v 'skipped' | sed 's/^/   /'
    ! echo "$status" | grep -q ' missing'
}

# The previous dotfiles-update called this after pulling, and the first update
# that delivers this file still runs that old script. Remove in phase 6.
install_mise_tools() {
    apply_mise_bootstrap
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
        mkdir -p "$(dirname "$socket")"
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

    # A fresh Apple Silicon Mac has no /usr/local/bin until something creates it.
    sudo mkdir -p "$(dirname "$target")"

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
