# dotfiles

## Dependencies

### macOS

```sh
brew install chezmoi
brew install fish
which fish | sudo tee -a /etc/shells
chsh -s "$(which fish)" # then logout and back in again after this
```

### Linux

```sh
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

