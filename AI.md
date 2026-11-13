# AI Context for Dotfiles Project

## Project Overview

**Name**: dotfiles  
**Purpose**: Personal configuration management system for consistent development environments across multiple devices and operating systems  
**Primary Technologies**: Bash, Fish shell, mise (bootstrap and dotfiles), 1Password SSH Agent  
**Repository**: davidwinter/dotfiles  

### Migration to mise bootstrap (in progress)

Machine setup is moving from stow and bash to `mise bootstrap` in phases. Read `docs/mise-migration-plan.md` before changing install, update, package, dotfile-linking or login-shell behaviour, and follow its "Moving machines safely" rules. In short: changes reach machines through `dotfiles-update`; any phase must work for a machine that skipped earlier ones; machine-specific mise config goes in `config.dotfiles-<module>.toml` modules selected by `MISE_ENV` (from `dotfiles-mise-env`); `MISE_MIN_VERSION` in `dotfiles-lib.sh` is the oldest supported mise.

### Core Goals
1. **One-liner installation** - New machines can be set up with a single command
2. **Cross-platform support** - Works on macOS, Ubuntu, Arch Linux, and WSL
3. **1Password integration** - SSH keys and git signing managed through 1Password
4. **Idempotent operations** - Safe to run installation multiple times
5. **Minimal prerequisites** - Only requires 1Password and curl to start

## Architecture & Design Philosophy

### Architecture Overview

```
User runs one-liner (curl | bash)
    ↓
bootstrap (minimal script)
    ├─ Checks: git installed
    ├─ Clones: repo via HTTPS
    ├─ Sets: PATH to include helper scripts
    └─ Executes: dotfiles-install
        ↓
dotfiles-install (main installer)
    ├─ Uses: helper scripts for all OS detection
    ├─ Runs: mise bootstrap (packages, dotfile links, macOS preferences, tools)
    ├─ Sets up: 1Password SSH agent + signing
    ├─ Switches: git remote HTTPS → SSH
    └─ Configures: Fish as default shell
        ↓
Helper Scripts (composable utilities)
    ├─ dotfiles-is-macos
    ├─ dotfiles-is-linux
    ├─ dotfiles-is-wsl
    ├─ dotfiles-is-ubuntu
    ├─ dotfiles-is-arch
    ├─ dotfiles-has-command
    └─ dotfiles-detect-linux-distro
        ↓
Used by:
    ├─ Installer scripts
    ├─ Update scripts
    ├─ Fish config
    └─ User's own scripts
```

### Core Principles
- **Simplicity over features** - Prefer straightforward solutions over complex abstractions
- **Explicit over implicit** - Configuration should be obvious and traceable
- **Safe by default** - Scripts use `set -euo pipefail` for error handling
- **OS-specific when necessary** - Detect platform differences and adapt automatically
- **Composable tools** - Small, focused scripts that can be combined
- **Self-documenting code** - Well-named functions and scripts over comments

### Key Design Decisions

#### Why mise for setup and linking?
- **Decision**: Use `mise bootstrap` for packages, dotfile links, macOS preferences and tools (replacing GNU Stow and hand-written install code; see `docs/mise-migration-plan.md`)
- **Rationale**: One declarative config; mise only changes what differs, so every run converges a machine to the config and new files need no migration
- **Trade-off**: Mise is young and changing quickly, so `MISE_MIN_VERSION` gates install and update
- **Implementation**: Each directory under `configs/` (and `scripts/`) is a dotfile group linked into `~` with one symlink per file (`symlink-each`, like `stow --no-folding`); machine-specific files are entries in `config.dotfiles-<module>.toml` modules

#### Why 1Password SSH Agent?
- **Decision**: Use 1Password for SSH key and git signing management
- **Rationale**: Keys never touch disk, biometric auth, works across devices
- **Trade-off**: Requires 1Password subscription and manual setup
- **Implementation**: SSH agent socket integration, op-ssh-sign for git

#### Why Fish Shell?
- **Decision**: Use Fish as default shell instead of Bash/Zsh
- **Rationale**: Better defaults, modern syntax, good auto-completion
- **Trade-off**: Not POSIX-compatible but installer still uses Bash
- **Implementation**: Fish config linked by mise, set as default shell

## Project Structure

```
dotfiles/
├── bootstrap             # Minimal bootstrap script (entry point for one-liner install)
├── configs/              # Config packages, each linked into ~ by mise (one symlink per file)
│   ├── fish/             # Fish shell configuration
│   │   └── .config/fish/config.fish
│   ├── git/              # Git configuration
│   │   └── .gitconfig
│   ├── git-wsl/          # WSL-specific git overrides
│   │   └── .config/git/config-wsl
│   ├── ssh/              # SSH configuration
│   │   └── .ssh/config
│   ├── starship/         # Starship prompt config
│   ├── vim/              # Vim configuration
│   ├── nano/             # Nano configuration
│   ├── hushlogin/        # Suppress login messages
│   ├── omarchy/          # Omarchy configs (dotfiles-omarchy module)
│   ├── ghostty-macOS/    # Ghostty terminal config (dotfiles-macos module)
│   └── mise/.config/mise/
│       ├── config.toml                 # Packages, dotfile groups, macOS preferences, tools
│       └── config.dotfiles-*.toml      # Machine-specific modules, chosen by MISE_ENV
├── scripts/              # Helper scripts and utilities (linked by mise's scripts group)
│   └── .local/
│       ├── bin/          # Executable scripts
│       │   ├── dotfiles-install
│       │   ├── dotfiles-update
│       │   ├── dotfiles-check-updates
│       │   ├── dotfiles-updates-notify
│       │   ├── dotfiles-doctor
│       │   # Migration scripts
│       │   ├── dotfiles-add-migration
│       │   ├── dotfiles-migrate
│       │   ├── dotfiles-migrations-status
│       │   # Helper scripts (composable utilities)
│       │   ├── dotfiles-is-macos
│       │   ├── dotfiles-is-linux
│       │   ├── dotfiles-is-wsl
│       │   ├── dotfiles-is-ubuntu
│       │   ├── dotfiles-is-arch
│       │   ├── dotfiles-is-omarchy
│       │   ├── dotfiles-has-1password
│       │   ├── dotfiles-has-command
│       │   ├── dotfiles-detect-linux-distro
│       │   └── dotfiles-mise-env      # Prints this machine's mise modules
│       └── lib/          # Shared library code
│           └── dotfiles-lib.sh
├── migrations/           # Migration scripts for structural changes
│   ├── 1767520410.sh
│   ├── 1767523066.sh
│   └── ...
├── AI.md                 # AI context documentation
└── README.md
```

### How config packages are linked
- Each directory under `configs/` is a package whose files mirror their location in `$HOME`; `configs/git/.gitconfig` is linked to `~/.gitconfig`
- Packages for every machine are dotfile groups in `config.toml` (`mode = "symlink-each"`): one relative symlink per file, directories kept real, so files apps create there stay out of the repo
- Packages for some machines (omarchy, git-1password, git-wsl, ghostty-macOS) are individual `[dotfiles]` file entries in a `config.dotfiles-<module>.toml` module, because a module's `dotfile_groups` list would replace the shared one
- `mise bootstrap` (run by install and update) creates any missing link; a new file in the repo is linked on the next `dotfiles-update`
- Mise stops before changing anything if a target already exists as a real file

## Key Files Explained

### Installation & Management Scripts

**`bootstrap`**
- Minimal entry point for one-liner installation
- Accepts optional repository argument (defaults to davidwinter/dotfiles)
- Clones repository via HTTPS to ~/dotfiles (no authentication required)
- Adds helper scripts to PATH temporarily
- Executes dotfiles-install
- No user-specific information hardcoded
- Only prerequisite: git (curl already succeeded if bootstrap is running)

**`dotfiles-install`**
- Main installer script, bootstraps entire system
- Sources shared library (dotfiles-lib.sh) for all check/ensure functions
- Checks mise is installed and new enough (`check_mise_ready`), then runs `mise bootstrap` (`apply_mise_bootstrap`): packages, dotfile links, macOS preferences and tools. It points mise at the repo's copy of the config, so it works before anything is linked
- Sets up 1Password SSH agent integration using `ensure_1password_agent` and `ensure_1password_ssh_sign`
- Switches git remote from HTTPS to SSH using `ensure_git_remote_ssh`
- Makes Fish the default shell using `ensure_fish_in_etc_shells` and `ensure_fish_is_default_shell`
- Marks all existing migrations as applied (only on fresh installs)
- Idempotent - safe to run multiple times

**`dotfiles-update`**
- Pulls latest changes from git repository, then restarts itself from the version just pulled
- Checks mise, runs `dotfiles-migrate` to apply pending migrations, then `mise bootstrap`
- Uses consistent bash style with set -euo pipefail

**`dotfiles-check-updates`**
- Checks for uncommitted local changes
- Checks for untracked files
- Fetches remote and compares with local
- Reports number of commits behind
- No longer hardcodes branch - uses current tracking branch

**`dotfiles-updates-notify`**
- Runs once per day on shell startup
- Caches last check date
- Provides non-intrusive update notifications

**`dotfiles-doctor`**
- Health check script that validates dotfiles installation
- Sources shared library (dotfiles-lib.sh) for all check functions
- Reports status of mise, packages, 1Password, git config, dotfile links (from `mise dot status`), fish shell, and migrations
- Provides clear feedback on what's working and what needs attention
- Suggests running `dotfiles-install` to fix issues

**`dotfiles-lib.sh`**
- Shared library containing all check and ensure functions
- Not executable - sourced by `dotfiles-install` and `dotfiles-doctor`
- Located at `scripts/.local/lib/dotfiles-lib.sh`
- Eliminates code duplication between install and doctor scripts
- All functions follow `check_*` and `ensure_*` naming pattern

**Helper Scripts** (see Helper Scripts section below)
- Small, composable utilities for OS detection and common tasks
- Used by installer, Fish config, and available for user scripts
- Includes `dotfiles-is-ssh-session` for gating 1Password-related setup on remote/headless hosts

### Configuration Files

**`.gitconfig`**
- Main git configuration
- Includes user name, email, signing key (hardcoded currently)
- Uses 1Password's op-ssh-sign for commit/tag signing
- Includes WSL-specific config via conditional include
- **Note**: Signing key is currently hardcoded per-machine

**`.ssh/config`**
- Configures 1Password SSH agent for all connections
- Uses `IdentityAgent ~/.1password/agent.sock`
- Only applies when not in SSH session (`test -z $SSH_TTY`)

**`config.fish`**
- Fish shell initialization
- Adds ~/.local/bin to PATH
- Activates mise for version management
- Sources Starship prompt
- WSL-specific: aliases ssh to ssh.exe for 1Password integrationon the Windows host to WSL

**`config-wsl`** (git-wsl package)
- WSL-specific git configuration
- Overrides sshCommand to use ssh.exe
- Different signing key for WSL environment (for Work, as I only use WSL for work currently)
- Different op-ssh-sign path (Windows installation, so 1Password prompts auth on Windows host)

## Platform-Specific Behaviors

### macOS
- Uses Homebrew for package installation
- 1Password socket: symlink from `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- op-ssh-sign: symlink from `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
- Installs JetBrains Mono Nerd Font via Homebrew cask
- Links: Ghostty config (`dotfiles-macos` module)

### Ubuntu
- Uses apt for package installation
- Requires sudo elevation
- 1Password: expects socket at `~/.1password/agent.sock`
- op-ssh-sign: symlink from `/opt/1Password/op-ssh-sign`

### Arch Linux
- Uses pacman for package installation
- Requires sudo elevation
- Installs ttf-jetbrains-mono-nerd font
- Links on Omarchy only: Hyprland and Waybar configs (`dotfiles-omarchy` module)

### WSL (Windows Subsystem for Linux)
- Detected via `grep -qi microsoft /proc/version`
- Uses Windows-side 1Password installation
- SSH commands aliased to `.exe` versions (ssh.exe, ssh-add.exe)
- op-ssh-sign path: `/mnt/c/Users/<username>/AppData/Local/1Password/app/8/op-ssh-sign-wsl`
- Git uses ssh.exe instead of native SSH
- Different signing key than macOS/Linux machines
- Links: git-wsl config (`dotfiles-wsl` module) to override git configuration
- Modules on WSL are `dotfiles-ubuntu,dotfiles-wsl`: packages still come from the underlying distro's manager
- **Note**: Windows username path is currently hardcoded per-machine

## Machine modules

Machine-specific mise config lives in `configs/mise/.config/mise/config.dotfiles-<module>.toml`. `dotfiles-mise-env` prints the modules for this machine; fish sets `MISE_ENV` from it, and install, update and doctor pass it to mise (`dotfiles_mise` in `dotfiles-lib.sh`).

| Module | Applies when (detected by) |
|---|---|
| `dotfiles-macos` | macOS (`dotfiles-is-macos`) |
| `dotfiles-<distro>`, e.g. `dotfiles-arch`, `dotfiles-ubuntu` | Linux, from `dotfiles-detect-linux-distro` (derivatives map via `ID_LIKE`) |
| `dotfiles-omarchy` | Omarchy (`dotfiles-is-omarchy`) |
| `dotfiles-wsl` | WSL (`dotfiles-is-wsl`) |
| `dotfiles-1password` | The 1Password app is installed (`dotfiles-has-1password`), however you're connected |

Naming a module with no file is harmless. Prefer an `os` key or a package-manager prefix in the shared `config.toml` over a module; use a module only when nothing in the shared config can express the condition.

### Adding a module
1. Make `dotfiles-mise-env` print it when the machine qualifies, using a `dotfiles-is-*` or `dotfiles-has-*` helper.
2. Create `config.dotfiles-<name>.toml`. Mise trusts it automatically because it's linked into `~/.config/mise`.

## Coding Standards & Conventions

### Bash Scripts
```bash
#!/usr/bin/env bash
set -euo pipefail  # ALWAYS use this for safety
```
- `-e`: Exit immediately on error
- `-u`: Error on undefined variables
- `-o pipefail`: Catch errors in pipes

### Portability (macOS and Linux)
Every script and migration must run unchanged on macOS, Ubuntu, Arch and WSL. macOS ships **bash 3.2** and **BSD** userland, so:
- **No bash 4+ features**: no `declare -A`/`local -A` (associative arrays), `mapfile`/`readarray`, `${var,,}`/`${var^^}`, `declare -n` namerefs, `&>>` or `|&`. Use newline-separated strings or plain indexed arrays instead
- **Empty arrays under `set -u`**: `"${arr[@]}"` on an empty array is an "unbound variable" error in bash 3.2. Guard with a length check or avoid the array
- **GNU vs BSD flags differ**: `sed -i` (BSD needs `sed -i ''`), `stat -c` vs `stat -f`, `date -d`, `readlink -f`, `grep -P`, `find -printf`. Prefer portable forms, or try GNU then fall back to BSD (e.g. `stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f"`)
- **Test on macOS** (or at least review against this list) before pushing anything that runs during `dotfiles-update`, since a failing migration blocks updates

### Script Organization
- **Helper scripts over functions** - Small executable scripts in PATH instead of sourced functions
- **Composable design** - Scripts call other scripts (e.g., `dotfiles-is-ubuntu` calls `dotfiles-detect-linux-distro`)
- **Minimal comments** - Well-named scripts and functions should be self-documenting
- **Use functions sparingly** - Only within larger scripts where extraction to separate script is overkill
- Handle errors with clear messages pointing to solutions

### File Naming
- Executables: lowercase with hyphens, no extension (e.g., `dotfiles-install`)
- Helper scripts: `dotfiles-<action>-<subject>` pattern (e.g., `dotfiles-is-macos`, `dotfiles-detect-linux-distro`)
- Config files: follow tool conventions (e.g., `.gitconfig`, `config.fish`)
- No executable bit on files that will be symlinked
- Avoid generic names that could conflict with system tools (hence `dotfiles-` prefix)

### Variable Naming
- UPPERCASE for constants: `DOTFILES_DIR="$HOME/dotfiles"`
- lowercase for local variables
- Use meaningful names, not abbreviations

### Helper Scripts
- **Location**: `scripts/.local/bin/dotfiles-*`
- **Language**: Bash (`#!/usr/bin/env bash`)
- **Exit codes**: 0=success/true, 1=failure/false, 2=usage error
- **Composability**: Scripts can call other helper scripts
- **No comments**: Scripts are self-documenting via clear naming
- **Examples**:
  - `dotfiles-is-macos` - Boolean check via exit code
  - `dotfiles-is-wsl` - Boolean check via exit code
  - `dotfiles-is-ssh-session` - Boolean check via exit code (checks `$SSH_CONNECTION`/`$SSH_CLIENT`)
  - `dotfiles-has-command git` - Takes argument, checks if command exists
  - `dotfiles-detect-linux-distro` - Outputs value to stdout

### Shared Library
- **Location**: `scripts/.local/lib/dotfiles-lib.sh`
- **Purpose**: Shared functions for `dotfiles-install` and `dotfiles-doctor`
- **Not executable**: Sourced by other scripts, not run directly
- **Functions**: All follow `check_*` and `ensure_*` naming pattern
  - `check_*` - Returns 0 if condition met, 1 if not (read-only)
  - `ensure_*` - Applies configuration to make condition true (uses `check_*` internally)
- **Examples**:
  - `check_bootstrap_packages` - Prints each mise-declared package's state; returns 1 if any is missing
  - `check_dotfiles_linked` - Returns 0 if every dotfile link is in place; prints any that isn't
  - `apply_mise_bootstrap` - Runs `mise bootstrap` with this machine's modules and the repo's mise config

### Helper Script Usage
```bash
# In bash scripts
if dotfiles-is-macos; then
    brew install package
fi

# In fish config
if dotfiles-is-wsl
    alias ssh=ssh.exe
end

# Capture output
DISTRO=$(dotfiles-detect-linux-distro)
echo "Detected: $DISTRO"
```

## Migration System

The dotfiles use a migration system to handle structural changes over time. This allows for safe evolution of the dotfiles structure without breaking existing installations.

### Overview

- **Migration files**: Stored in `migrations/` directory
- **Naming**: Unix timestamp from last git commit (e.g., `1705324800.sh`)
- **Tracking**: Applied migrations tracked via empty marker files in `~/.local/state/dotfiles/migrations/`
- **Execution**: Migrations run automatically on `dotfiles-update`

### Architecture

```
dotfiles-update runs
    ↓
git pull (get latest code)
    ↓
dotfiles-migrate
    ├─ Scans: migrations/*.sh files
    ├─ Checks: ~/.local/state/dotfiles/migrations/ for applied/skipped
    ├─ Runs: pending migrations in chronological order
    ├─ Executes: bash -euo pipefail <migration-file>
    └─ Tracks: Creates empty marker file on success
        ↓
On failure:
    ├─ Prompts: Skip and continue? (interactive with gum or read)
    ├─ Skip: Creates marker in skipped/ subdirectory
    └─ Stop: Exits with error, user can retry later
```

### Creating Migrations

**Generate a new migration:**
```bash
dotfiles-add-migration
```

This creates a file in `migrations/` using the timestamp of your last git commit.

**Migration file structure:**
```bash
# Migration: Description of what this does

echo "Performing migration..."

# Just plain bash code - no boilerplate needed
# The runner provides error handling (set -euo pipefail)

mkdir -p "$DOTFILES_DIR/new-directory"
mv old-location new-location
```

**Key points:**
- No shebang needed
- No `set -euo pipefail` needed (provided by runner)
- Can use `$DOTFILES_DIR` variable
- Should be idempotent when possible
- Should fail fast on errors

### Migration State

**State location:** `~/.local/state/dotfiles/migrations/`

**Structure:**
```
~/.local/state/dotfiles/migrations/
├── 1705324800.sh          # Empty file = migration applied
├── 1705411200.sh          # Empty file = migration applied
└── skipped/
    └── 1705497600.sh      # Empty file = migration skipped
```

**Benefits:**
- Easy to inspect: `ls ~/.local/state/dotfiles/migrations/`
- Easy to manage: Delete marker to re-run migration
- Atomic: File creation is atomic operation
- No parsing: Just check if file exists

### Helper Scripts

**dotfiles-add-migration**
- Creates new migration file with timestamp from last git commit
- Timestamp format: Unix timestamp (10 digits)
- Ensures `migrations/` directory exists
- Checks for existing file with same timestamp

**dotfiles-migrate**
- Finds all `migrations/*.sh` files
- Checks which are pending (not in state directory)
- Runs pending migrations in chronological order
- Captures output and exit codes
- On failure: Prompts to skip or stop
- Creates marker files for applied/skipped migrations
- Uses `gum confirm` if available, falls back to `read -p`

**dotfiles-migrations-status**
- Shows all migrations with their status
- Status indicators: ✅ applied, ⏭️ skipped, ⏳ pending
- Summary counts

### Workflow

**Normal update flow:**
```bash
$ dotfiles-update
🔄 Updating dotfiles...
✅ Git pull successful

Running migration: 1705324800
Moving packages to config/...
✅ Migration applied

✅ All migrations complete

✅ Dotfiles updated successfully
```

**Migration failure flow:**
```bash
$ dotfiles-update
🔄 Updating dotfiles...
✅ Git pull successful

Running migration: 1705324800
❌ Migration failed with exit code: 1

Output:
mkdir: cannot create directory 'config': Permission denied

Migration 1705324800 failed. Skip and continue? [y/N] n

❌ Stopping due to migration failure
❌ Migrations failed
   Your dotfiles are updated but migrations didn't complete
   Please fix the issue and run: dotfiles-migrate
```

**Check status:**
```bash
$ dotfiles-migrations-status
Migration Status
================

✅ applied  1705324800
✅ applied  1705411200
⏳ pending  1705497600

Total: 3 (2 applied, 0 skipped, 1 pending)
```

### Design Decisions

**Why Unix timestamps?**
- Derived from git commit timestamp (reproducible)
- Chronologically sortable
- Simple and deterministic
- No collision concerns for personal repos

**Why empty marker files?**
- Simpler than parsing a list file
- Easy to inspect with standard tools (`ls`, `find`)
- Atomic operations (file creation)
- Easy to manually manage (delete to re-run)

**Why subprocess execution?**
- Clean error capture (exit codes)
- Output capture for better error messages
- Process isolation (can't break parent shell)
- Can apply error handling via `bash -euo pipefail`

**Why interactive skip?**
- Sometimes migrations fail for transient reasons
- User can decide to skip and continue vs stop
- Tracked separately so skipped migrations don't re-run
- Graceful degradation without `gum` dependency

### Best Practices

**When writing migrations:**
1. Make them idempotent when possible (can be run multiple times safely)
2. Check prerequisites before making changes
3. Use `$DOTFILES_DIR` instead of hardcoded paths
4. Fail fast on errors (rely on `-e` flag)
5. Add descriptive echo messages for progress
6. Keep migrations focused on one logical change

**When NOT to use migrations:**
- Changing config values (just update the file)
- Adding files, packages, dotfile groups or macOS preferences (mise applies them on the next update)

**When you MUST use a migration:**
- Removing something mise created or used to create, such as a link to a deleted file or a LaunchAgent; mise doesn't remove what a config no longer declares
- Any one-off structural change mise can't converge by itself
- Migrations must not rely on `dotfiles-*` commands, which later phases may change or remove; use plain commands

### Common Patterns

**Moving directories:**
```bash
# Migration: Move stow packages to config/ directory

echo "Moving stow packages to config/..."

cd "$DOTFILES_DIR"

mkdir -p config

for pkg in fish git starship ssh; do
    [[ -d "$pkg" ]] && mv "$pkg" "config/"
done
```

**Cleaning up old files:**
```bash
# Migration: Remove deprecated config files

echo "Removing deprecated files..."

[[ -f "$HOME/.old-config" ]] && rm "$HOME/.old-config"
[[ -d "$HOME/.old-directory" ]] && rm -rf "$HOME/.old-directory"
```

**Updating symlinks:**
```bash
# Migration: Re-stow packages after directory move

echo "Re-stowing packages..."

cd "$DOTFILES_DIR"

for pkg in fish git starship; do
    stow --restow --dir=config --target="$HOME" "$pkg"
done
```

## Package Management

System packages and macOS apps are declared under `[bootstrap.packages]` in `configs/mise/.config/mise/config.toml` and installed by `mise bootstrap` (migration phase 2). Command-line tools are under `[tools]` in the same file.

- One entry per package manager, with that manager's package name: `"pacman:fish" = "latest"`, `"apt:fish" = "latest"`, `"brew:fish" = { os = "macos" }`. Mise skips entries for a manager that isn't installed.
- `"latest"` means "make sure it's installed"; mise doesn't upgrade it.
- Give Homebrew entries `os = "macos"` so a Linuxbrew install doesn't pick them up.
- On macOS, git, curl and jq come with the system, so there are no Homebrew entries for them.
- Before adding a Homebrew cask, check it downloads from the vendor: `brew info --cask <name>`.
- The installer's `mise bootstrap` run points mise at the repo's config (`MISE_CONFIG_DIR`), so packages install before any dotfile is linked. `dotfiles-update` uses the same `apply_mise_bootstrap`.

## 1Password Integration

### Prerequisites (User Must Setup)
1. 1Password application installed
2. Settings → Developer → "Use the SSH Agent" enabled
3. SSH keys added to 1Password vault
4. For git signing: Public key fingerprint noted

### How It Works

**SSH Agent:**
- 1Password runs an SSH agent that holds keys
- Socket location varies by OS
- dotfiles-install creates symlink to `~/.1password/agent.sock` for consistency across most platforms
- SSH config uses `IdentityAgent` to point to this socket
- WSL: Must use ssh.exe to access Windows-side agent

**Git Signing:**
- Uses SSH keys instead of GPG keys (`gpg.format = ssh`)
- On machines with the 1Password app (`dotfiles-1password` module) the `git-1password` package sets `gpg.ssh.program` to the `git-ssh-sign` wrapper (`~/.local/bin/git-ssh-sign`, resolved via PATH), not `op-ssh-sign` directly
- The wrapper dispatches: in an SSH session with a forwarded agent (`$SSH_CONNECTION` and `$SSH_AUTH_SOCK` both set) it signs via `ssh-keygen` through the forwarded agent so the biometric prompt lands on the local machine; otherwise it signs locally via `op-ssh-sign`. This stops a desktop that is also SSH'd into from popping its own 1Password on remote commits
- Signs commits and tags automatically when configured
- Public key fingerprint stored in .gitconfig as `user.signingkey`

### Remote / Headless Installs
- When installing over SSH (`$SSH_CONNECTION` set), `dotfiles-install` auto-skips the 1Password agent and op-ssh-sign setup. The `git-1password` files are linked wherever the 1Password app is installed (`dotfiles-1password` module), whether or not you're connected over SSH; `git-ssh-sign` picks the forwarded agent while one is live
- Base `.gitconfig` does not hardcode `gpg.ssh.program`; the override lives in the separate `git-1password` package (which also ships the `git-ssh-sign` wrapper) and is included via `~/.config/git/config-1password` (git silently ignores missing includes)
- Git signing on remote hosts works through the forwarded SSH agent via native `ssh-keygen` — the user must have `ForwardAgent yes` set for the remote on their local `~/.ssh/config`

### Current Limitations
- Signing keys are hardcoded per machine (no templating yet)
- No automatic key discovery from 1Password
- WSL requires manual Windows username in path
- No validation that 1Password is correctly configured before proceeding
- Tied to davidwinter/dotfiles repo currently, so others can't use the same dotfiles project setup without needing to manually modify some of the dotfiles shell scripts
- Git signing keys are hardcoded per machine (no templating system)
- WSL username path hardcoded in 1Password setup
- We're not using a config file to store user specific configurations, such as repo location or other user-specific settings
- No automated testing or CI. Suggested minimal setup: a GitHub Action running shellcheck and a `mise bootstrap --dry-run` in a fresh container
- Folded directories: links are one per file (`symlink-each`), so no directory is ever a link into the repo. Older stow-based installs were unfolded by migration `1791027819.sh`; root `.gitignore` and the per-package `.gitignore` files (excluded from linking) still list the known runtime strays as a safety net

## Common Tasks

### Adding config files
1. For every machine: create `configs/<package>/` mirroring the target paths, add a `[dotfile_groups.<package>]` table (`root`, `mode = "symlink-each"`) and add it to `dotfile_groups` in `config.toml`. A new file in an existing package needs nothing else.
2. For some machines: add `[dotfiles]` entries for each file to the right `config.dotfiles-<module>.toml`.
3. Check with `mise bootstrap --dry-run` and `mise dot status`, then run `dotfiles-update`.

### Supporting a New OS
1. Add detection function: `is_<os>() { ... }`
2. Update ensure_installed() with package manager logic
3. Handle 1Password paths in ensure_1password_agent() and ensure_1password_ssh_sign()
4. Add a machine module or `os`-limited entries in the mise config if needed
5. Test thoroughly on actual system

### Modifying Installation Script
- Always maintain idempotency
- Check if something exists before creating it
- Provide clear success/failure messages with emoji indicators
- Exit with non-zero on failure
- Update all supported OS paths simultaneously

## Known Issues & Quirks

### Git Signing Keys
- **Issue**: Signing keys are hardcoded in .gitconfig
- **Impact**: Can't easily use same dotfiles on multiple machines with different keys
- **Workaround**: Manual edit of .gitconfig or use of .gitconfig.local (not implemented)

### WSL Paths
- **Issue**: Windows username is hardcoded in git-wsl/config-wsl
- **Impact**: Doesn't work if Windows username differs
- **Workaround**: Manual edit of config-wsl file
- **Note**: The path is duplicated: `config-wsl` hardcodes the full path including the username and `app/8`, while `ensure_1password_ssh_sign` resolves the username at runtime but still hardcodes `app/8`. Pointing `config-wsl` at `/usr/local/bin/op-ssh-sign` (which the installer creates) would leave one source of truth

### 1Password Socket (Linux)
- **Issue**: No automatic socket creation on Linux
- **Impact**: User must manually configure or script errors out
- **Workaround**: Script provides message but doesn't help user fix it

### Existing files on a new machine
- **Issue**: Mise refuses to link over a file that already exists
- **Impact**: Install stops (before changing any dotfile) and names the files
- **Workaround**: Move each file aside (e.g. `mv ~/.gitconfig ~/.gitconfig.bak`) and run `dotfiles-install` again

### Fish Shell Change
- **Issue**: chsh may not work in all environments (containers, etc.)
- **Impact**: Installation "succeeds" but Fish isn't default shell
- **Workaround**: Script provides manual chsh command to run

### Review backlog (2026-10-03)
Found in a project review and deliberately deferred. Pick these up individually.

- **Daily update check blocks the prompt**: `dotfiles-updates-notify` runs `git fetch` synchronously on interactive shell start. When offline the fetch fails, the cache date isn't written, and every new shell blocks on the fetch again. Write the date regardless, or run the check in the background
- **Shell startup spawns bash helpers**: `config.fish` calls `dotfiles-is-macos`, `dotfiles-has-command`, etc., each a separate bash process. Fish builtins (`test (uname) = Darwin`, `type -q`) avoid that
- **`dotfiles-check-updates` edge cases**: reports "updates available (0 commits behind)" when local is ahead of the remote; compare the behind count instead. With no upstream, `git rev-parse @{u}` fails under `set -e` before the friendly error prints

## Dependencies & Prerequisites

### User Must Install Before Running
- **1Password** (GUI application)
  - Must enable SSH Agent in settings
  - Must add SSH keys to vault
- **curl** - For downloading installer
- **sudo access** (Linux only) - For installing packages and creating symlinks in /usr/local

### Installer Provides
- System packages from `[bootstrap.packages]` (git, curl, stow, fish, font; btop and Firefox on macOS) and tools from `[tools]` (starship, eza, lazygit and more), all via mise
- JetBrains Mono Nerd Font
- Symlinks for 1Password helpers
- Dotfiles repository clone
- Symlinked configuration files

## Testing Approach

### Current State
- Manual testing on real machines
- No automated tests
- Tested platforms: macOS (Apple Silicon), Ubuntu, Arch Linux, WSL2

### Testing Considerations
- Installation is idempotent - safe to run multiple times
- Test by running installer on fresh VM or container
- Verify symlinks: `ls -la ~/.gitconfig` should show arrow to dotfiles
- Verify 1Password: `ssh-add -l` should list keys
- Verify git signing: Create test commit and check signature

## AI Assistant Guidelines

### When Making Suggestions
1. **Maintain cross-platform compatibility** - Any change must work on all supported OSes; macOS, Ubuntu, Ubuntu (via WSL2), Omarchy/ArchLinux
2. **Preserve one-liner install** - Don't break the curl-to-bash installation method
3. **Keep idempotency** - Scripts must be safe to run multiple times
4. **Consider existing configs** - Users might have files that would conflict
5. **Minimal dependencies** - Don't add new required tools without strong justification
6. **Prefer helper scripts over functions** - Extract reusable logic to small scripts in `scripts/.local/bin/`
7. **No summary markdown files** - Don't create `PHASE-X-SUMMARY.md` or similar documentation artifacts

### When Adding Features
1. Ask: "Does this make setup more complicated?"
2. Ensure all supported OSes are handled
3. Update README.md with user-facing changes
4. Update AI.md if architecture/conventions change
5. Maintain backward compatibility when possible
6. Provide clear error messages with solutions

### Code Style Preferences
- **Minimal comments** - Code should be self-documenting via clear naming
- **Well-named scripts/functions** - Names should clearly indicate purpose
- **Helper scripts over inline logic** - Extract common checks to reusable scripts
- **Bash over sh** - Use bash features (`[[`, `==`) for better readability
- **Composable tools** - Small scripts that do one thing well and can be combined

### Common Pitfalls to Avoid
- **Don't assume Homebrew location** - Use $HOMEBREW_PREFIX or detect
- **Don't use sudo with Homebrew** - Homebrew explicitly discourages this
- **WSL needs special handling** - Always check `dotfiles-is-wsl` for 1Password paths
- **Git config includes are conditional** - config-wsl only loads on WSL
- **Config packages mirror structure** - git/.gitconfig becomes ~/.gitconfig
- **Script paths must be portable** - Use $HOME, not absolute paths
- **1Password paths differ by OS** - Check all platforms when modifying
- **Don't add comments to simple helper scripts** - If a 2-line script needs comments, rename it
- **Don't create inline functions for reusable logic** - Create helper scripts instead
- **Adding a new file to an existing package doesn't need a migration** - `dotfiles-update` runs `mise bootstrap`, which links any file that isn't linked yet
- **`declare -A` under `set -u`** - An associative array declared with bare `declare -A arr` (no elements assigned) is treated as unbound by bash's `set -u` when later referenced (e.g. `${#arr[@]}`) — use `declare -A arr=()`. Migrations run under `set -u` via `dotfiles-migrate`, so this breaks the "nothing to do" path on a second run if missed.

### Suggested Improvements (Future Considerations)
- Pre-flight validation that 1Password is installed and configured
- Automatic backup of existing files that block a dotfile link on a new machine
- Machine-specific config system (.gitconfig.local support)
- Health check command to verify everything works
- Better WSL username detection
- 1Password key discovery helper
- Dry-run mode to preview changes

## Installation Flow

1. User runs one-liner: `curl https://raw.githubusercontent.com/USER/dotfiles/main/bootstrap | bash`
2. Bootstrap script downloads and executes
3. Checks for git (only prerequisite - curl already succeeded)
4. Clones dotfiles repository to ~/dotfiles via HTTPS (no authentication needed)
5. Adds ~/dotfiles/scripts/.local/bin to PATH
6. Executes dotfiles-install from cloned repository
7. Installer sources shared library (dotfiles-lib.sh)
8. Detects OS and distribution using helper scripts (dotfiles-is-macos, dotfiles-is-linux, etc.)
9. Checks mise, then runs `mise bootstrap` with the repo's copy of the mise config (`apply_mise_bootstrap`): installs packages, links dotfiles, applies macOS preferences, installs tools
10. Sets up 1Password agent socket and op-ssh-sign symlinks (using `ensure_1password_agent` and `ensure_1password_ssh_sign`)
11. Switches git remote from HTTPS to SSH (using `ensure_git_remote_ssh`)
13. Adds fish to /etc/shells and sets as default shell (using `ensure_fish_in_etc_shells` and `ensure_fish_is_default_shell`)
14. Marks all existing migrations as applied (only on fresh installs)
15. Displays success messages with status indicators

## Update Flow

1. User runs `dotfiles-update` or notified by `dotfiles-updates-notify`
2. `dotfiles-check-updates` runs once per day on interactive shell startup
3. Script runs git pull in ~/dotfiles (via SSH after initial setup), then restarts itself so the steps below come from the version just pulled
4. Script checks mise is installed and at least `MISE_MIN_VERSION`, stopping before any change if not
5. Script runs `dotfiles-migrate` to apply any pending migrations
6. Script runs `mise bootstrap --yes` with this machine's `MISE_ENV` modules and the repo's copy of the mise config: packages, dotfile links (including files new since the last update), macOS preferences, tools

## Health Check Flow

1. User runs `dotfiles-doctor`
2. Doctor sources shared library (dotfiles-lib.sh)
3. Runs `check_*` functions to validate:
   - mise installed and new enough, and this machine's modules
   - Packages installed (from `mise bootstrap packages status`)
   - 1Password agent socket and SSH sign helper configured
   - Git remote using SSH
   - Dotfiles linked (from `mise dot status`)
   - Fish shell in /etc/shells and set as default
   - All migrations applied
4. Reports status with ✅ for OK, ❌ for issues
5. Suggests running `dotfiles-install` to fix any issues found

## Philosophy on Configuration

- **Explicit is better than implicit** - No hidden magic
- **Portable over optimal** - Works everywhere rather than perfect on one platform
- **Self-documenting over commented** - Well-named scripts and functions over explanatory comments
- **Composable over monolithic** - Small tools that do one thing well
- **Safe over fast** - Rather fail early than silently corrupt
- **Convention over configuration** - Sensible defaults, minimal choices

## Current Architecture

### Key Features
- ✅ Bootstrap script for one-liner installation
- ✅ Helper scripts for reusable OS detection and common tasks
- ✅ Main installer uses helper scripts (no inline functions)
- ✅ All scripts use consistent bash style (set -euo pipefail, [[, ==)
- ✅ Fish config uses helper scripts (no duplication)
- ✅ Git remote automatically switches from HTTPS to SSH
- ✅ Zero code duplication across bash scripts and Fish config
- ✅ Migration system for safe structural changes over time
- ✅ Automatic migration execution on updates
- ✅ Interactive failure handling with skip option
- ✅ Shared library (dotfiles-lib.sh) with check/ensure functions
- ✅ Health check script (dotfiles-doctor) to validate installation
- ✅ Configs organized in dedicated configs/ directory
- ✅ Scripts organized in scripts/.local/bin and scripts/.local/lib
