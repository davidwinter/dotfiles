fish_add_path /usr/local/bin
fish_add_path /usr/local/sbin
fish_add_path /usr/local/go/bin
fish_add_path /snap/bin
fish_add_path /opt/homebrew/bin

if which python3 > /dev/null
    fish_add_path (python3 -m site --user-base)/bin
end

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/Dropbox/bin
fish_add_path $HOME/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.deno/bin
fish_add_path $HOME/.tfenv/bin

# https://github.com/fish-shell/fish-shell/issues/6643
set -gx GPG_TTY (tty)

set -gx LC_ALL en_GB.UTF-8
set -gx BROWSER open
set -gx EDITOR vim

set -gx GOPATH $HOME/go
set -gx NODE_PATH /usr/local/lib/node_modules
set -gx fish_greeting ''

alias g=git
alias tailscale=/Applications/Tailscale.app/Contents/MacOS/Tailscale

# Linux
if test -f ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
end

# proto
set -gx PROTO_HOME "$HOME/.proto"
set -gx PATH "$PROTO_HOME/shims:$PROTO_HOME/bin" $PATH

# orbstack
source ~/.orbstack/shell/init.fish 2>/dev/null || :
