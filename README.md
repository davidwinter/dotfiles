# dotfiles

Ensure that `chezmoi` is installed:

```sh
brew install chezmoi
```

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

