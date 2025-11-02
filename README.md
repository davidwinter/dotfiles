# dotfiles

## Dependencies

Ensure 1Password is installed.

### macOS

```sh
ln -s /Applications/1Password.app/Contents/MacOS/op-ssh-sign /usr/local/bin/op-ssh-sign
brew install stow
brew install fish
which fish | sudo tee -a /etc/shells
chsh -s "$(which fish)" # then logout and back in again after this
```

### Linux

```sh
ln -s /opt/1Password/op-ssh-sign /usr/local/bin/op-ssh-sign
sudo apt update
sudo apt install stow
sudo apt install fish
chsh -s "$(which fish)" # then logout and back in again after this
```

## Setup

To setup, run:

```sh
cd
git clone git@github.com:davidwinter/dotfiles.git
cd dotfiles
./bootstrap.sh
```
