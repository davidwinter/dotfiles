alias g=git

fish_add_path ~/.local/bin

if dotfiles-is-macos
    source ~/.orbstack/shell/init.fish 2>/dev/null; or true
end

if test -d /opt/homebrew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH
end

if not dotfiles-has-command mise
    echo "ℹ️  mise not found - installing..."
    curl https://mise.run | sh
    mise activate fish | source
    mise install
else
    mise activate fish | source
end

set -gx fish_greeting ''

if dotfiles-is-wsl
    alias ssh=ssh.exe
    alias ssh-add=ssh-add.exe
end

starship init fish | source

if status is-interactive; and dotfiles-has-command dotfiles-updates-notify
    dotfiles-updates-notify
end
