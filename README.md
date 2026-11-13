# dotfiles

## Before you install

The installer needs `git`, `curl` and [mise](https://mise.jdx.dev) 2026.11.6 or newer, and uses your system package manager (Homebrew, apt or pacman) to install the rest. 1Password provides SSH keys and commit signing on machines you use directly.

### 1Password (all desktop machines)

1. Install 1Password and sign in.
2. Open Settings → Developer and turn on "Use the SSH Agent". Opt into displaying key names if asked.
3. When 1Password offers to update `~/.ssh/config`, decline. The dotfiles manage that file.
4. Add your SSH public key to your GitHub account. The dotfiles repo is cloned and pulled over HTTPS but pushed over SSH, so pushing uses this key.

On WSL, install 1Password for Windows and turn on its SSH agent there instead.

### macOS

1. Set up 1Password as above.
2. Install [Homebrew](https://brew.sh). It installs the Xcode command line tools for you, which include `git`, so there's no need to install those separately. When it finishes, run the `eval "$(/opt/homebrew/bin/brew shellenv)"` line it prints so `brew` works in the current terminal.
3. Install mise: `brew install mise`

After installing, a few macOS settings have no dependable command-line setting, so set them once by hand:

- **Default web browser:** System Settings → Desktop & Dock → Default web browser → Firefox. macOS asks you to confirm any change of browser.
- **Recent items:** System Settings → Control Centre → "Recent documents, applications and servers" → None. This empties the Apple menu's Recent Items, and Finder's Go → Recent Folders.
- **Finder sidebar:** Finder → Settings → Sidebar, untick Recents.
- **Spotlight:** System Settings → Spotlight, turn off "Show related content".
- **Lock immediately when the lid closes or the display sleeps:** System Settings → Lock Screen → "Require password after screen saver begins or display is turned off" → Immediately. From a terminal: `sysadminctl -screenLock immediate -password -`, which asks for your password; that's why the dotfiles can't set it on every update.
- **Caps Lock as Escape:** System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys, set Caps Lock to Escape. macOS keeps this per keyboard, so repeat it for each external keyboard.

The dotfiles set the rest of the macOS preferences (Dock, hot corners, dark mode, Finder, clock and so on) in `configs/mise/.config/mise/config.toml`. Some take effect only after you log out and back in.

### Arch Linux and Omarchy

A standard Omarchy install already includes `git`, mise and 1Password, so only the 1Password setup above is needed.

On plain Arch:

```bash
sudo pacman -S --needed git curl mise
```

Then install 1Password and set it up as above.

### Ubuntu

```bash
sudo apt install git curl
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
2. Installs system packages and apps through mise, with Homebrew, apt or pacman: GNU Stow, fish, a JetBrains Mono Nerd Font, and on macOS btop and Firefox. The list lives under `[bootstrap.packages]` in `configs/mise/.config/mise/config.toml`.
3. Where the 1Password app is installed, links its `op-ssh-sign` helper into `~/.local/bin` for commit signing, and on macOS its SSH agent socket to `~/.1password/agent.sock`.
4. Sets git to push the dotfiles repo over SSH (`pushInsteadOf` in `.gitconfig`).
5. Links the config files into your home directory through mise, one symlink per file.
6. Installs the command-line tools in the mise config with `mise install`.
7. Makes fish your login shell through mise (adding it to `/etc/shells` if needed).

Command-line tools such as starship, eza, lazygit, node and the GitHub CLI are defined in the mise config (`configs/mise`) too.

## Remote / headless install

To install on a remote machine you SSH into (cloud servers, etc.) where you don't want 1Password installed directly:

1. On your **local** machine, make sure 1Password's SSH agent is turned on (you already need this for normal use).
2. On your **local** machine, add `ForwardAgent yes` for the remote host in `~/.ssh/config`:
   ```
   Host my-cloud-box
     ForwardAgent yes
   ```
3. SSH into the remote, follow the "Before you install" steps for its platform (skipping 1Password), and run the install command.

Without the 1Password app on the remote, the dotfiles leave out its 1Password setup and git signs with `ssh-keygen` through your forwarded agent, so 1Password on your local machine prompts on each commit.

### Using a desktop machine over SSH

You can also SSH into a machine that has its own 1Password, such as a Linux desktop. While you're connected with agent forwarding, fish keeps `~/.ssh/agent.sock` pointing at your forwarded agent, and both `ssh` and git commit signing use it from every terminal on that machine. That includes tmux, zellij and herdr terminals started before you connected, so prompts appear on the machine you connected from.

Once you disconnect, the same terminals go back to the machine's own 1Password, so prompts appear there when you're back at it. If the forwarded agent ever stops working while you're still connected (for example after closing the newer of two SSH connections), open a new SSH connection to repoint it.

## Helper scripts

The dotfiles include helper scripts for common tasks:

### Management scripts
- `dotfiles-update` - Pull the latest changes, run any migrations, and apply the mise config (packages, links, preferences, tools)
- `dotfiles-check-updates` - Check for updates without applying
- `dotfiles-doctor` - Check dotfiles health and report any issues

### Migration scripts
- `dotfiles-add-migration` - Create a new migration file
- `dotfiles-migrate` - Run pending migrations
- `dotfiles-migrations-status` - Check if there are pending migrations

### Detection helpers
- `dotfiles-is-macos` - Check if running on macOS
- `dotfiles-is-linux` - Check if running on Linux
- `dotfiles-is-wsl` - Check if running on WSL
- `dotfiles-is-ubuntu` - Check if running on Ubuntu
- `dotfiles-is-arch` - Check if running on Arch Linux
- `dotfiles-is-omarchy` - Check if running on Omarchy
- `dotfiles-has-1password` - Check if the 1Password app is installed on this machine
- `dotfiles-mise-env` - Print the mise config modules for this machine (fish sets `MISE_ENV` from it)
- `dotfiles-is-ssh-session` - Check if the current shell is an SSH session
- `dotfiles-has-command` - Check if a command exists
- `dotfiles-detect-linux-distro` - Output the Linux distribution name

These helper scripts are available in your PATH after installation and are used throughout the dotfiles for consistent OS detection and logic.

## Configuration

Everything is configured in the mise config, `configs/mise/.config/mise/` (AI.md has the details):

- **`config.toml`** applies to every machine: tools, system packages and apps (`[bootstrap.packages]`), dotfile groups, and macOS preferences. Limit an entry to one OS with `os = "macos"` or `os = "linux"`, or to one package manager with its prefix (`pacman:`, `apt:`, `brew:`, `brew-cask:`); mise skips entries for a package manager that isn't installed.
- **`config.dotfiles-<module>.toml`** files hold config for some machines only. Each machine works out its own modules (`dotfiles-mise-env`), for example `dotfiles-macos`, `dotfiles-arch`, `dotfiles-omarchy`, `dotfiles-wsl` and `dotfiles-1password`.

### Adding a system package

Add one entry per package manager, using that manager's package name:

```toml
[bootstrap.packages]
"pacman:ttf-jetbrains-mono-nerd" = "latest"
"apt:fonts-jetbrains-mono" = "latest"
"brew-cask:font-jetbrains-mono-nerd-font" = { os = "macos" }
```

`"latest"` means "make sure it's installed"; mise doesn't upgrade it. Machines pick up new entries on their next `dotfiles-update`.

### Adding config files

Each directory under `configs/` mirrors where its files go in your home directory: `configs/git/.gitconfig` is linked to `~/.gitconfig`, one symlink per file, with directories kept real.

- **A new file in an existing package** needs nothing else. It's linked on the next `dotfiles-update`.
- **A new package for every machine:** create `configs/<package>/`, then add it to `dotfile_groups` with a matching `[dotfile_groups.<package>]` table in `config.toml`.
- **Files for some machines only:** add a `[dotfiles]` entry for each file to the right `config.dotfiles-<module>.toml`, as `config.dotfiles-omarchy.toml` does.

Check with `mise bootstrap --dry-run` before updating.

### Supported platforms and modules

Distributions based on Arch or Ubuntu are detected through `ID_LIKE` in `/etc/os-release`, so Omarchy gets `dotfiles-arch` (plus `dotfiles-omarchy`) and Pop!_OS gets `dotfiles-ubuntu`. Other distributions get a module named after their own `ID`, and mise only installs packages from the package managers it supports. WSL running Ubuntu gets `dotfiles-ubuntu` and `dotfiles-wsl`.

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

## Health check

To check if your dotfiles are configured correctly:

```bash
dotfiles-doctor
```

This will report on:
- Installed packages
- 1Password configuration
- The dotfiles repo pushing over SSH
- Dotfile links
- Login shell (fish)
- Migration status

If issues are found, run `dotfiles-update` to fix them. To rerun the full install on an existing machine, run the install command again; it reuses the existing clone.

## Migrations

The dotfiles use a migration system to handle structural changes over time. Migrations are automatically run when you update your dotfiles.

### How it works

- Migration files are stored in `migrations/` directory
- Each migration is a bash script named with a Unix timestamp (e.g., `1705324800.sh`)
- Applied migrations are tracked in `~/.local/state/dotfiles/migrations/`
- Migrations run automatically when you run `dotfiles-update`

### Creating a migration

To create a new migration:

```bash
dotfiles-add-migration
```

This creates a new migration file using the timestamp of your last git commit. Edit the file and add your migration logic (just plain bash code, no boilerplate needed).

Before writing one, check whether the mise config can do it instead: to remove a file or link from every machine, add a `[dotfiles]` entry with `mode = "absent"`. AI.md lists the options.

### Managing migrations

Check migration status:

```bash
dotfiles-migrations-status
```

Manually run pending migrations:

```bash
dotfiles-migrate
```

### Migration behavior

- Migrations run in chronological order (by timestamp)
- If a migration fails, you'll be prompted to skip it or stop
- Skipped migrations are tracked separately and won't run again
- Migration state is stored in `~/.local/state/dotfiles/migrations/`
- On fresh installs, all existing migrations are automatically marked as applied

## Supported platforms

- macOS (Apple Silicon and Intel)
- Arch Linux, including Omarchy
- Ubuntu, and distributions based on it
- Windows Subsystem for Linux (WSL2) running Ubuntu
