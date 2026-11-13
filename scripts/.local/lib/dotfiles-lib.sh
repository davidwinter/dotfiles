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

# Runs mise with this machine's config modules (MISE_ENV, from
# dotfiles-mise-env) and with the repo's copy of the mise config. Using the
# repo's copy means it works before ~/.config/mise is linked (on a fresh
# install, or when a new module file hasn't been linked yet), and mise's own
# "mise" dotfile group then links ~/.config/mise to it.
dotfiles_mise() {
    MISE_CONFIG_DIR="${DOTFILES_DIR:-$HOME/dotfiles}/configs/mise/.config/mise" \
        MISE_ENV="$(dotfiles-mise-env)" mise "$@"
}

# Applies the whole mise config: packages, dotfile links, macOS preferences
# and tools. Extra arguments are passed on (e.g. --only packages).
apply_mise_bootstrap() {
    if dotfiles_mise bootstrap --yes "$@"; then
        echo "   ✅ mise bootstrap applied"
    else
        echo "   ❌ mise bootstrap stopped - see the error above" >&2
        echo "      If it refused to overwrite existing files, move each one aside" >&2
        echo "      (e.g. mv ~/.gitconfig ~/.gitconfig.bak), then run it again" >&2
        return 1
    fi
}

# Prints each declared package's state; returns 1 if any is missing.
check_bootstrap_packages() {
    local status
    status="$(dotfiles_mise bootstrap packages status 2>&1)" || true
    echo "$status" | grep -v 'skipped' | sed 's/^/   /'
    ! echo "$status" | grep -q ' missing'
}

# Prints one line per dotfile group (by package name), then per machine-specific
# file (with its module), and for a group that isn't fully linked, each file
# that isn't. Returns 1 if anything isn't in place. Columns in mise's verbose
# status are separated by two or more spaces: target, mode, source, config
# file, state.
check_dotfiles_linked() {
    local ok=0 target mode source config state src file rel
    while IFS=$'\t' read -r target mode source config state; do
        src="${source/#\~/$HOME}"
        if [[ "$mode" == "symlink-each" ]]; then
            if [[ "$state" == "applied" ]]; then
                echo "   ✅ $(basename "$src")"
                continue
            fi
            echo "   ❌ $(basename "$src") ($state)"
            while IFS= read -r file; do
                rel="${file#$src/}"
                if [[ "$(realpath "$HOME/$rel" 2>/dev/null)" != "$(realpath "$file")" ]]; then
                    echo "      not linked: ~/$rel"
                fi
            done < <(find "$src" -type f ! -name '.gitignore')
        else
            config="$(basename "$config" .toml)"
            if [[ "$state" == "applied" ]]; then
                echo "   ✅ $target (${config#config.})"
            else
                echo "   ❌ $target (${config#config.}, $state)"
            fi
        fi
        [[ "$state" == "applied" ]] || ok=1
    done < <(dotfiles_mise dot status --verbose 2>/dev/null \
        | awk -F '  +' -v OFS='\t' 'NF >= 5 && $2 ~ /^(symlink|symlink-each|copy|template)$/ { print $1, $2, $3, $4, $NF }' \
        | sort -s -t $'\t' -k2,2r)
    return "$ok"
}

# Old dotfile-update scripts call these after pulling, and the first update
# that delivers this file still runs the old script once. Remove in phase 6.
stow_configs_for_host() {
    apply_mise_bootstrap
}
install_mise_tools() {
    :
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

# === Login shell ===

# Prints the login shell state from mise ([bootstrap.user]); returns 1 if it
# isn't the configured shell yet. Status columns: wanted, current, state.
check_login_shell() {
    local wanted current state
    read -r wanted current state < <(dotfiles_mise bootstrap user status 2>/dev/null | head -1)
    if [[ "$state" == "set" ]]; then
        echo "   ✅ Login shell is $current"
        return 0
    fi
    echo "   ❌ Login shell is ${current:-unknown}, not ${wanted:-the configured shell} (${state:-no status})"
    return 1
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
