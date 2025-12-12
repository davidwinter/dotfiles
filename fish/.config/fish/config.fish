alias g=git

fish_add_path ~/.local/bin

# orbstack
if test (uname) = Darwin
    source ~/.orbstack/shell/init.fish 2>/dev/null; or true
end

if test -d /opt/homebrew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH
end

if command -v mise &>/dev/null
    mise activate fish | source
end

if command -v dotfiles-updates-notify &>/dev/null
    dotfiles-updates-notify
end

set -gx fish_greeting ''

if test -S ~/.1password/agent.sock
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
end

if grep -qi microsoft /proc/version
    alias ssh=ssh.exe
    alias ssh-add=ssh-add.exe
end

starship init fish | source
