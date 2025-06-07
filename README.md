# dotfiles

## Dependencies

### macOS

```sh
ln -s /Applications/1Password.app/Contents/MacOS/op-ssh-sign /usr/local/bin/op-ssh-sign
brew install chezmoi
brew install fish
which fish | sudo tee -a /etc/shells
chsh -s "$(which fish)" # then logout and back in again after this
```

### Linux

```sh
ln -s /opt/1Password/op-ssh-sign /usr/local/bin/op-ssh-sign
sudo snap install chezmoi --classic
sudo apt update
sudo apt install fish
chsh -s /usr/bin/fish # then logout and back in again after this
```

## Setup

To setup, run:

```sh
chezmoi init --apply git@github.com:davidwinter/dotfiles.git
```

To edit files:

```sh
chezmoi cd
nano file.txt
chezmoi apply
```
