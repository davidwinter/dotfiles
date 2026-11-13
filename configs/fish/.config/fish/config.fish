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
    # Which config.dotfiles-*.toml modules apply to this machine, so mise
    # commands typed here match what dotfiles-update applies.
    if dotfiles-has-command dotfiles-mise-env
        set -gx MISE_ENV (dotfiles-mise-env)
    end
    mise activate fish | source
else
    echo "⚠️  mise not found - install it from https://mise.jdx.dev then run: mise install"
end

set -gx fish_greeting ''

# Over SSH, use a stable agent link so terminals that outlive this login
# (tmux, zellij, herdr) keep working after a reconnect. A fresh login hands us
# its own forwarded socket (not a symlink), so point the link at it. If the
# link ever goes stale, open a new SSH connection. ~/.ssh/config and
# git-ssh-sign use the link while it's live, and 1Password otherwise.
if set -q SSH_CONNECTION; and set -q SSH_AUTH_SOCK
    if test -S "$SSH_AUTH_SOCK"; and not test -L "$SSH_AUTH_SOCK"
        ln -sfn "$SSH_AUTH_SOCK" ~/.ssh/agent.sock
    end
    set -gx SSH_AUTH_SOCK ~/.ssh/agent.sock
end

if dotfiles-is-wsl
    alias ssh=ssh.exe
    alias ssh-add=ssh-add.exe
end

if not dotfiles-has-command zed; and dotfiles-has-command zeditor
    alias zed=zeditor
end

# starship comes from mise, so it's missing until `mise install` has run.
if dotfiles-has-command starship
    starship init fish | source
end

if status is-interactive; and dotfiles-has-command dotfiles-updates-notify
    dotfiles-updates-notify
end
