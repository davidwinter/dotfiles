set -gx PATH /usr/local/bin $PATH
set -gx PATH /usr/local/sbin $PATH
set -gx PATH /usr/local/go/bin $PATH
set -gx PATH $HOME/.cargo/bin $PATH
set -gx PATH $HOME/Dropbox/bin $PATH
set -gx PATH $HOME/.rbenv/shims $PATH

set -gx BROWSER open
set -gx EDITOR vim

set -gx GOPATH $HOME/go
set -gx NODE_PATH /usr/local/lib/node_modules
set -gx fish_greeting ''
set -gx NVM_DIR ~/.nvm

if which rbenv > /dev/null
	rbenv rehash >/dev/null ^&1
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
