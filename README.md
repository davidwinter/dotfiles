# dotfiles

## Dependencies

- git
- curl
- 1Password (recommended, setup instructions below)

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/davidwinter/dotfiles/main/bootstrap | bash
```

Or with a custom repository:

```bash
curl -fsSL https://raw.githubusercontent.com/davidwinter/dotfiles/main/bootstrap | bash -s -- youruser/dotfiles
```

## 1Password Setup

The dotfiles system uses 1Password for SSH key management and git commit signing.

### Prerequisites

1. Install 1Password
2. Open 1Password Settings → Developer
3. Enable "Use the SSH Agent"
4. Opt into displaying key names if prompted
5. When prompted, do not update the local `~/.ssh/config` file (dotfiles handles this)
6. **Add your SSH public key to GitHub** - The installer will switch the git remote from HTTPS to SSH, so you need your 1Password-managed SSH key added to your GitHub account

## What It Does

1. Clones your dotfiles to `~/dotfiles`
2. Installs required packages (stow, fish, starship, mise, eza, lazygit, lazydocker)
3. Sets up 1Password SSH agent integration
4. Symlinks configuration files using GNU Stow
5. Makes Fish your default shell

## Updating

The dotfiles will check for updates once per day when you start a new shell.

To manually update:

```bash
dotfiles-update
```

To check for updates without applying:

```bash
dotfiles-check-updates
```

## Supported Platforms

- macOS (Apple Silicon & Intel)
- Ubuntu Linux
- Arch Linux
- Windows Subsystem for Linux (WSL2)