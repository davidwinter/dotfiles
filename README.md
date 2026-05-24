# dotfiles

## Dependencies

- git
- jq
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

## Remote / Headless Install

To install on a remote machine you SSH into (cloud servers, etc.) where you don't want 1Password installed directly:

1. On your **local** machine, ensure 1Password's "Use the SSH Agent" is enabled (you already need this for normal use).
2. On your **local** machine, add `ForwardAgent yes` for the remote host in `~/.ssh/config`:
   ```
   Host my-cloud-box
     ForwardAgent yes
   ```
3. SSH into the remote and run the standard one‑liner.

The installer detects the SSH session via `$SSH_CONNECTION` and:
- Skips 1Password agent/op-ssh-sign setup.
- Skips the `git-1password` config override (which would point at the missing `op-ssh-sign` binary).
- Git signing falls back to native `ssh-keygen`, which signs via the forwarded SSH agent — so your 1Password app on your local machine prompts for biometrics on each commit.

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

1. Clones your dotfiles to `~/dotfiles` (via HTTPS)
2. Installs required packages (stow, fish, starship, mise, eza, lazygit, lazydocker)
3. Sets up 1Password SSH agent integration
4. Switches git remote from HTTPS to SSH (for authenticated push/pull)
5. Symlinks configuration files using GNU Stow
6. Makes Fish your default shell

## Helper Scripts

The dotfiles include helper scripts for common tasks:

### Management Scripts
- `dotfiles-install` - Install and configure dotfiles
- `dotfiles-update` - Pull latest changes from git and run migrations
- `dotfiles-check-updates` - Check for updates without applying
- `dotfiles-doctor` - Check dotfiles health and report any issues
- `dotfiles-validate` - Validate the dotfiles.json configuration file

### Migration Scripts
- `dotfiles-add-migration` - Create a new migration file
- `dotfiles-migrate` - Run pending migrations
- `dotfiles-migrations-status` - Check if there are pending migrations

### Detection Helpers
- `dotfiles-is-macos` - Check if running on macOS
- `dotfiles-is-linux` - Check if running on Linux
- `dotfiles-is-wsl` - Check if running on WSL
- `dotfiles-is-ubuntu` - Check if running on Ubuntu
- `dotfiles-is-arch` - Check if running on Arch Linux
- `dotfiles-is-ssh-session` - Check if the current shell is an SSH session
- `dotfiles-has-command` - Check if a command exists
- `dotfiles-detect-linux-distro` - Output the Linux distribution name

These helper scripts are available in your PATH after installation and are used throughout the dotfiles for consistent OS detection and logic.

## Configuration

The dotfiles system uses a `dotfiles.json` configuration file to define which packages to install and which configs to apply. This makes it easy to customize for different platforms and use cases.

### Configuration File Structure

The `dotfiles.json` file has two main sections:

- **`packages`** - List of packages to install
- **`configs`** - List of configuration directories to apply with Stow

#### Simple Packages/Configs

For packages or configs that work the same across all platforms:

```json
{
  "packages": [
    "git",
    "stow",
    "starship"
  ],
  "configs": [
    "git",
    "ssh",
    "starship"
  ]
}
```

**Note:** The `scripts` config is automatically included and should not be added to the JSON file.

#### Platform-Specific Items

For items that only apply to certain platforms:

```json
{
  "configs": [
    {
      "name": "ghostty-macOS",
      "platforms": ["macos"]
    },
    {
      "name": "omarchy",
      "platforms": ["arch"]
    }
  ]
}
```

#### Platform-Specific Package Names

For packages that have different names on different platforms:

```json
{
  "packages": [
    {
      "name": "nerd-font",
      "platforms": {
        "macos": "font-jetbrains-mono-nerd-font",
        "arch": "ttf-jetbrains-mono-nerd",
        "ubuntu": "fonts-jetbrains-mono"
      }
    }
  ]
}
```

### Supported Platform Identifiers

- **`macos`** - macOS (any version)
- **`linux`** - Any Linux distribution
- **`wsl`** - Windows Subsystem for Linux
- **`arch`** - Arch Linux
- **`ubuntu`** - Ubuntu
- **`debian`** - Debian
- **`fedora`** - Fedora
- **`rhel`** - Red Hat Enterprise Linux
- **`centos`** - CentOS
- **`alpine`** - Alpine Linux

#### Trait-Gated Items

`platforms` answers "what OS"; `traits` answers "what kind of host". Add a `traits` field alongside (or instead of) `platforms` to gate an item on host characteristics:

```json
{
  "configs": [
    {
      "name": "git-1password",
      "traits": ["desktop"]
    },
    {
      "name": "git-wsl",
      "traits": ["wsl"]
    }
  ]
}
```

When both `platforms` and `traits` are set on an item, **both must match** (AND between fields, OR within each list).

### Supported Traits

- **`desktop`** - Host is not currently an SSH session (i.e., the install is running locally on the machine, not over SSH). Use this to gate items that require GUI apps like 1Password.
- **`wsl`** - Host is running under Windows Subsystem for Linux.

### Validating Configuration

To validate your `dotfiles.json` configuration:

```bash
dotfiles-validate
```

This will check for:
- Valid JSON syntax
- Required fields (packages, configs)
- Proper object structure
- Valid platform identifiers

## Updating

The dotfiles will check for updates once per day when you start a new shell.

To manually update:

```bash
dotfiles-update
```

This will pull the latest changes and automatically run any pending migrations.

To check for updates without applying:

```bash
dotfiles-check-updates
```

## Health Check

To check if your dotfiles are configured correctly:

```bash
dotfiles-doctor
```

This will report on:
- Installed packages
- 1Password configuration
- Git remote configuration
- Stowed configurations
- Fish shell setup
- Migration status

If issues are found, run `dotfiles-install` to fix them.

## Migrations

The dotfiles use a migration system to handle structural changes over time. Migrations are automatically run when you update your dotfiles.

### How It Works

- Migration files are stored in `migrations/` directory
- Each migration is a bash script named with a Unix timestamp (e.g., `1705324800.sh`)
- Applied migrations are tracked in `~/.local/state/dotfiles/migrations/`
- Migrations run automatically when you run `dotfiles-update`

### Creating a Migration

To create a new migration:

```bash
dotfiles-add-migration
```

This creates a new migration file using the timestamp of your last git commit. Edit the file and add your migration logic (just plain bash code, no boilerplate needed).

### Managing Migrations

Check migration status:

```bash
dotfiles-migrations-status
```

Manually run pending migrations:

```bash
dotfiles-migrate
```

### Migration Behavior

- Migrations run in chronological order (by timestamp)
- If a migration fails, you'll be prompted to skip it or stop
- Skipped migrations are tracked separately and won't run again
- Migration state is stored in `~/.local/state/dotfiles/migrations/`
- On fresh installs, all existing migrations are automatically marked as applied

## Supported Platforms

- macOS (Apple Silicon & Intel)
- Ubuntu Linux
- Arch Linux
- Windows Subsystem for Linux (WSL2)
