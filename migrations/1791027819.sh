# Migration: unfold any stow-folded config directory on existing installs
#
# ensure_dotfiles_config_present now stows with --no-folding (see
# dotfiles-lib.sh), but existing installs that ran the old stow command may
# still have whole config directories (~/.ssh, ~/.config/fish,
# ~/.claude/agents, ~/.claude/lenses, ...) collapsed into a single directory
# symlink into the repo. Anything an app later writes into one of those
# directories — SSH's authorized_keys/known_hosts, a forwarded agent socket,
# fish_variables — lands inside the dotfiles working tree instead of a real
# directory in $HOME.
#
# This walks every file every config package owns, finds the first (topmost)
# ancestor directory under $HOME that is a folded symlink into the repo,
# unfolds it into a real directory, moves out anything under it that isn't
# tracked by git (the stray runtime files causing this), and re-stows the
# owning package with --no-folding so the tracked files come back as
# per-file symlinks.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIGS_DIR="$DOTFILES_DIR/configs"

dir_mode() {
    stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1" 2>/dev/null
}

is_tracked() {
    # True if $1 (absolute path inside the repo) is a tracked file, or a
    # directory containing at least one tracked file.
    local rel="${1#$DOTFILES_DIR/}"
    if [[ -d "$1" ]]; then
        [[ -n "$(git -C "$DOTFILES_DIR" ls-files "$rel")" ]]
    else
        git -C "$DOTFILES_DIR" ls-files --error-unmatch "$rel" &>/dev/null
    fi
}

# Collect the set of folded target directories under $HOME, each mapped to
# the package that owns them.
declare -A folded_pkgs=()

for pkg_path in "$CONFIGS_DIR"/*/; do
    pkg_dir="${pkg_path%/}"
    pkg="$(basename "$pkg_dir")"

    while IFS= read -r file; do
        rel="${file#$pkg_dir/}"
        path="$HOME"
        IFS='/' read -ra parts <<< "$rel"
        for part in "${parts[@]}"; do
            path="$path/$part"
            if [[ -L "$path" ]]; then
                real="$(realpath "$path" 2>/dev/null)" || break
                if [[ "$real" == "$DOTFILES_DIR"* ]] && [[ -d "$real" ]]; then
                    folded_pkgs["$path"]="$pkg"
                fi
                break
            fi
        done
    done < <(find "$pkg_dir" -type f)
done

if [[ ${#folded_pkgs[@]} -eq 0 ]]; then
    echo "  No folded config directories found — nothing to do"
    exit 0
fi

declare -A pkgs_to_restow=()

for target in "${!folded_pkgs[@]}"; do
    pkg="${folded_pkgs[$target]}"
    real="$(realpath "$target")"

    echo "Unfolding $target (package: $pkg)"

    mode="$(dir_mode "$real")"
    [[ -z "$mode" ]] && mode=755

    rm "$target"
    mkdir -m "$mode" "$target"

    # Move anything NOT tracked by git out of the repo and into the new real
    # directory — the stray runtime files that caused the problem
    # (authorized_keys, known_hosts*, agent sockets, fish_variables, ...).
    # Tracked files are left in place for stow to re-link below.
    while IFS= read -r -d '' entry; do
        if ! is_tracked "$entry"; then
            echo "  Moving stray $(basename "$entry") out of the repo"
            mv "$entry" "$target/"
        fi
    done < <(find "$real" -mindepth 1 -maxdepth 1 -print0)

    pkgs_to_restow["$pkg"]=1
done

echo "Re-stowing affected packages with --no-folding..."
for pkg in "${!pkgs_to_restow[@]}"; do
    if stow --restow --no-folding --dir="$CONFIGS_DIR" --target="$HOME" "$pkg"; then
        echo "  ✅ $pkg re-stowed"
    else
        echo "  ⚠️  Failed to re-stow $pkg" >&2
        exit 1
    fi
done

echo "✅ Migration complete"
