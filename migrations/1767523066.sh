# Migration: Remove legacy fish function symlinks

# Helper function to remove symlink if it exists
remove_symlink() {
    if [[ -L "$1" ]]; then
        rm "$1"
    fi
}

echo "Removing legacy fish function symlinks..."

remove_symlink "$HOME/.config/fish/functions/fish_prompt.fish"
remove_symlink "$HOME/.config/fish/functions/git_prompt.fish"

echo "  ✅ Removed legacy fish function symlinks"
