add_to_path /usr/local/bin
add_to_path /usr/local/sbin
add_to_path /usr/local/go/bin
add_to_path /snap/bin
add_to_path /opt/homebrew/bin

if which python3 > /dev/null
    add_to_path (python3 -m site --user-base)/bin
end

add_to_path $HOME/.cargo/bin
add_to_path $HOME/Dropbox/bin
add_to_path $HOME/bin
add_to_path $HOME/.local/bin
add_to_path $HOME/.deno/bin

set -gx BROWSER open
set -gx EDITOR vim

set -gx GOPATH $HOME/go
set -gx NODE_PATH /usr/local/lib/node_modules
set -gx fish_greeting ''

# Linux
if test -f ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
end

# macOS
if which brew > /dev/null; and test -f (brew --prefix asdf)/libexec/asdf.fish
	source (brew --prefix asdf)/libexec/asdf.fish
end
