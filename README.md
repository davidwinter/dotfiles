# dotfiles

## Before you install

The installer needs `git`, `jq` and `curl`, uses your system package manager (Homebrew, apt or pacman) to install the rest, and expects [mise](https://mise.jdx.dev) for command-line tools. 1Password provides SSH keys and commit signing on machines you use directly.

### 1Password (all desktop machines)

1. Install 1Password and sign in.
2. Open Settings → Developer and turn on "Use the SSH Agent". Opt into displaying key names if asked.
3. When 1Password offers to update `~/.ssh/config`, decline. The dotfiles manage that file.
4. Add your SSH public key to your GitHub account. The installer switches the repo's remote from HTTPS to SSH, so pushing and pulling use this key.

On WSL, install 1Password for Windows and turn on its SSH agent there instead.

### macOS

1. Set up 1Password as above.
2. Install [Homebrew](https://brew.sh). It installs the Xcode command line tools for you, which include `git`, so there's no need to install those separately. When it finishes, run the `eval "$(/opt/homebrew/bin/brew shellenv)"` line it prints so `brew` works in the current terminal.
3. Install mise: `brew install mise`
4. Check `jq --version` works. macOS 15 and later include it; on older versions run `brew install jq`.

### Arch Linux and Omarchy

A standard Omarchy install already includes `git`, `jq`, mise and 1Password, so only the 1Password setup above is needed.

On plain Arch:

```bash
sudo pacman -S --needed git jq curl mise
```

Then install 1Password and set it up as above.

### Ubuntu

```bash
sudo apt install git jq curl
```

Install mise using [its installation guide](https://mise.jdx.dev/installing-mise.html) (the apt repository keeps it up to date). On a desktop, install 1Password and set it up as above.

### WSL

Follow the Ubuntu steps inside WSL, and set up 1Password for Windows as above. Git in WSL uses Windows' `ssh.exe` and 1Password's `op-ssh-sign-wsl`, so 1Password on Windows handles keys and signing.

`configs/git-wsl/.config/git/config-wsl` sets the path to `op-ssh-sign-wsl`, which includes the Windows username (`DavidWinter`). If you fork these dotfiles, change it to yours.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/davidwinter/dotfiles/main/bootstrap | bash
```

Or with a custom repository:

```bash
curl -fsSL https://raw.githubusercontent.com/davidwinter/dotfiles/main/bootstrap | bash -s -- youruser/dotfiles
```

The installer asks for your password to install packages, link 1Password's signing helper and make fish your login shell. If a config file it manages already exists (for example `~/.gitconfig` or `~/.ssh/config`), it asks whether to back it up, delete it or skip that package.

Then:

1. Open a new terminal, which starts fish.
2. Run `dotfiles-doctor` to check everything is in place.

The first time you push or pull over SSH, ssh asks you to confirm GitHub's host key and 1Password asks you to approve using your key.

## What it does

1. Clones the repo to `~/dotfiles` over HTTPS.
2. Installs packages with Homebrew, apt or pacman: GNU Stow, fish, a JetBrains Mono Nerd Font, and btop on macOS. The list lives in `dotfiles.json` and `system/core-packages.json`.
3. Links 1Password's SSH agent socket (macOS) and its `op-ssh-sign` helper into `/usr/local/bin`. Skipped when installing over SSH.
4. Switches the repo's git remote from HTTPS to SSH.
5. Links the config files into your home directory with GNU Stow.
6. Installs the command-line tools in the mise config with `mise install`.
7. Adds fish to `/etc/shells` and makes it your login shell.

Command-line tools such as starship, eza, lazygit, node and the GitHub CLI are defined in the mise config (`configs/mise`), not in `dotfiles.json`.

## Remote / headless install

To install on a remote machine you SSH into (cloud servers, etc.) where you don't want 1Password installed directly:

1. On your **local** machine, make sure 1Password's SSH agent is turned on (you already need this for normal use).
2. On your **local** machine, add `ForwardAgent yes` for the remote host in `~/.ssh/config`:
   ```
   Host my-cloud-box
     ForwardAgent yes
   ```
3. SSH into the remote, follow the "Before you install" steps for its platform (skipping 1Password), and run the install command.

The installer detects the SSH session and skips 1Password setup and the `git-1password` config. Git then signs with `ssh-keygen` through your forwarded agent, so 1Password on your local machine prompts on each commit.

### Using a desktop machine over SSH

You can also SSH into a machine that has its own 1Password, such as a Linux desktop. While you're connected with agent forwarding, fish keeps `~/.ssh/agent.sock` pointing at your forwarded agent, and both `ssh` and git commit signing use it from every terminal on that machine. That includes tmux, zellij and herdr terminals started before you connected, so prompts appear on the machine you connected from.

Once you disconnect, the same terminals go back to the machine's own 1Password, so prompts appear there when you're back at it. If the forwarded agent ever stops working while you're still connected (for example after closing the newer of two SSH connections), open a new SSH connection to repoint it.

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

- **`macos`** - macOS
- **`arch`** - Arch Linux, and distributions based on it such as Omarchy
- **`ubuntu`** - Ubuntu, and distributions based on it such as Pop!_OS
- **`linux`** - In the object form of platform-specific package names, a fallback name for any Linux platform without its own entry

Distributions based on Arch or Ubuntu are detected through `ID_LIKE` in `/etc/os-release`. Other distributions report their own `ID` (for example `debian` or `fedora`), but the installer only knows how to install packages with Homebrew, apt and pacman. WSL is a trait, not a platform: WSL running Ubuntu has the platform `ubuntu` and the trait `wsl`.

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

This pulls the latest changes, runs any pending migrations, links any config files added since you last updated, and installs any tools newly added to the mise config.

Tools installed by mise update separately:

```bash
mise upgrade
```

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

- macOS (Apple Silicon and Intel)
- Arch Linux, including Omarchy
- Ubuntu, and distributions based on it
- Windows Subsystem for Linux (WSL2) running Ubuntu
