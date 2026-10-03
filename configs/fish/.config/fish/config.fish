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

if dotfiles-has-command mise
    mise activate fish | source
else
    echo "⚠️  mise not found - install it from https://mise.jdx.dev then run: mise install"
end

set -gx fish_greeting ''

if dotfiles-is-wsl
    alias ssh=ssh.exe
    alias ssh-add=ssh-add.exe
end

if not dotfiles-has-command zed; and dotfiles-has-command zeditor
    alias zed=zeditor
end

starship init fish | source

if status is-interactive; and dotfiles-has-command dotfiles-updates-notify
    dotfiles-updates-notify
end
