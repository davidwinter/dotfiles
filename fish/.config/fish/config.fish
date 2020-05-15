add_to_path /usr/local/bin
add_to_path /usr/local/sbin
add_to_path /usr/local/go/bin
add_to_path /snap/bin
add_to_path $HOME/.cargo/bin
add_to_path $HOME/Dropbox/bin
add_to_path $HOME/.rbenv/bin
add_to_path $HOME/.rbenv/shims
add_to_path $HOME/bin
add_to_path $HOME/.local/bin

set -gx BROWSER open
set -gx EDITOR vim

set -gx GOPATH $HOME/go
set -gx NODE_PATH /usr/local/lib/node_modules
set -gx fish_greeting ''
set -gx NVM_DIR ~/.nvm

if which rbenv > /dev/null
	rbenv init - | source
end

if which jenv > /dev/null
	jenv rehash 2>/dev/null
end

if test -f ~/.config/fish/nvm-wrapper/nvm.fish
	source ~/.config/fish/nvm-wrapper/nvm.fish
end

if which pyenv > /dev/null
	status --is-interactive; and source (pyenv init -|psub)
end

if which pipenv > /dev/null
	eval (pipenv --completion)
end

if which direnv > /dev/null
	direnv hook fish | source
end

if which brew > /dev/null; and test -d (brew --prefix asdf)
    source (brew --prefix asdf)/asdf.fish
end

if test -f ~/.asdf/asdf.fish
	source ~/.asdf/asdf.fish
end

