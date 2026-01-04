# AI Context for Dotfiles Project

## Project Overview

**Name**: dotfiles  
**Purpose**: Personal configuration management system for consistent development environments across multiple devices and operating systems  
**Primary Technologies**: Bash, Fish shell, GNU Stow, 1Password SSH Agent  
**Repository**: davidwinter/dotfiles  

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
    ├─ Installs: packages (brew/apt/pacman)
    ├─ Sets up: 1Password SSH agent + signing
    ├─ Switches: git remote HTTPS → SSH
    ├─ Stows: config packages (symlinks)
    └─ Configures: Fish as default shell
        ↓
Helper Scripts (composable utilities)
    ├─ dotfiles-is-macos
    ├─ dotfiles-is-linux
    ├─ dotfiles-is-wsl
    ├─ dotfiles-is-ubuntu
    ├─ dotfiles-is-archlinux
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

#### Why GNU Stow?
- **Decision**: Use GNU Stow for symlink management
- **Rationale**: Simple, transparent, easy to understand what's happening
- **Trade-off**: Less flexible than chezmoi/yadm but much simpler
- **Implementation**: Each tool/config is a separate "stow package"

#### Why 1Password SSH Agent?
- **Decision**: Use 1Password for SSH key and git signing management
- **Rationale**: Keys never touch disk, biometric auth, works across devices
- **Trade-off**: Requires 1Password subscription and manual setup
- **Implementation**: SSH agent socket integration, op-ssh-sign for git

#### Why Fish Shell?
- **Decision**: Use Fish as default shell instead of Bash/Zsh
- **Rationale**: Better defaults, modern syntax, good auto-completion
- **Trade-off**: Not POSIX-compatible but installer still uses Bash
- **Implementation**: Fish config managed via stow, set as default shell

## Project Structure

```
dotfiles/
├── bootstrap             # Minimal bootstrap script (entry point for one-liner install)
├── fish/                 # Fish shell configuration (stow package)
│   └── .config/fish/config.fish
├── git/                  # Git configuration (stow package)
│   └── .gitconfig
├── git-wsl/              # WSL-specific git overrides (stow package)
│   └── .config/git/config-wsl
├── ssh/                  # SSH configuration (stow package)
│   └── .ssh/config
├── scripts/              # Helper scripts and utilities (stow package)
│   └── .local/bin/
│       ├── dotfiles-install
│       ├── dotfiles-update
│       ├── dotfiles-check-updates
│       ├── dotfiles-updates-notify
│       # Migration scripts
│       ├── dotfiles-add-migration
│       ├── dotfiles-migrate
│       ├── dotfiles-migrations-status
│       # Helper scripts (composable utilities)
│       ├── dotfiles-is-macos
│       ├── dotfiles-is-linux
│       ├── dotfiles-is-wsl
│       ├── dotfiles-is-ubuntu
│       ├── dotfiles-is-archlinux
│       ├── dotfiles-has-command
│       └── dotfiles-detect-linux-distro
├── migrations/           # Migration scripts for structural changes
│   ├── 1705324800.sh
│   └── ...
├── starship/             # Starship prompt config (stow package)
├── vim/                  # Vim configuration (stow package)
├── nano/                 # Nano configuration (stow package)
├── hushlogin/            # Suppress login messages (stow package)
├── omarchy/              # Arch Linux specific configs (stow package)
├── ghostty-macOS/        # Ghostty terminal config for macOS (stow package)
├── AI.md                 # AI context documentation
└── README.md
```

### How Stow Packages Work
- Each directory represents a stow "package"
- Files inside mirror their target location in $HOME
- Example: `git/.gitconfig` gets symlinked to `~/.gitconfig`
- Running `stow --dir=dotfiles --target=$HOME git` creates the symlink

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
- Uses helper scripts exclusively (no inline functions)
- Detects OS and installs appropriate packages
- Sets up 1Password SSH agent integration
- Switches git remote from HTTPS to SSH for authenticated push/pull
- Stows config packages (creates symlinks)
- Makes Fish the default shell
- Idempotent - safe to run multiple times

**`dotfiles-update`**
- Simple git pull to update dotfiles repo
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

**Helper Scripts** (see Helper Scripts section below)
- Small, composable utilities for OS detection and common tasks
- Used by installer, Fish config, and available for user scripts

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
- Stows: ghostty-macOS package

### Ubuntu
- Uses apt for package installation
- Requires sudo elevation
- 1Password: expects socket at `~/.1password/agent.sock`
- op-ssh-sign: symlink from `/opt/1Password/op-ssh-sign`

### Arch Linux
- Uses pacman for package installation
- Requires sudo elevation
- Installs ttf-jetbrains-mono-nerd font
- Stows: omarchy package for Arch-specific configs

### WSL (Windows Subsystem for Linux)
- Detected via `grep -qi microsoft /proc/version`
- Uses Windows-side 1Password installation
- SSH commands aliased to `.exe` versions (ssh.exe, ssh-add.exe)
- op-ssh-sign path: `/mnt/c/Users/<username>/AppData/Local/1Password/app/8/op-ssh-sign-wsl`
- Git uses ssh.exe instead of native SSH
- Different signing key than macOS/Linux machines
- Stows: git-wsl package to override git configuration
- **Note**: Windows username path is currently hardcoded per-machine

## Coding Standards & Conventions

### Bash Scripts
```bash
#!/usr/bin/env bash
set -euo pipefail  # ALWAYS use this for safety
```
- `-e`: Exit immediately on error
- `-u`: Error on undefined variables
- `-o pipefail`: Catch errors in pipes

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
  - `dotfiles-has-command git` - Takes argument, checks if command exists
  - `dotfiles-detect-linux-distro` - Outputs value to stdout

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
- Adding new config files (just stow them)
- Changing config values (just update the file)
- Installing new packages (update installer)
- Use migrations for structural changes only

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

### Installed Packages
**Required for functionality:**
- git, stow, fish, starship, lazygit, lazydocker, mise, eza
- JetBrains Mono Nerd Font (for proper terminal rendering using eza, and looks nice within Ghostty)

**Package Installation Logic:**
```
ensure_installed() function handles:
- macOS: brew install
- Ubuntu: apt install (with apt update)
- Arch: pacman -Syu
- Checks if already installed before attempting
```

### Adding New Packages
1. Add to PACKAGES array in dotfiles-install
2. Ensure package name matches across package managers (or handle differences)
3. Test on all supported platforms

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
- op-ssh-sign binary acts as signing program
- Signs commits and tags automatically when configured
- Public key fingerprint stored in .gitconfig as `user.signingkey`

### Current Limitations
- Signing keys are hardcoded per machine (no templating yet)
- No automatic key discovery from 1Password
- WSL requires manual Windows username in path
- No validation that 1Password is correctly configured before proceeding
- Tied to davidwinter/dotfiles repo currently, so others can't use the same dotfiles project setup without needing to manually modify some of the dotfiles shell scripts
- Stow packages are currently stored in the root of the project directory, rather than within a `configs` or similar directory structure (can now be changed via migration)
- We're not using a config file to store user specific configurations, such as repo location or other user-specific settings
- We're not using a config file to store packages that users want installed, or configurations to be handled via stow, making the concept of the project reusable by others

## Common Tasks

### Adding a New Stow Package
1. Create directory: `dotfiles/<package-name>/`
2. Mirror the target structure: `dotfiles/<package-name>/.config/tool/config`
3. Add package name to STOW_PACKAGES array in dotfiles-install
4. Test locally: `stow --dir=. --target=$HOME <package-name>`

### Supporting a New OS
1. Add detection function: `is_<os>() { ... }`
2. Update ensure_installed() with package manager logic
3. Handle 1Password paths in ensure_1password_agent() and ensure_1password_ssh_sign()
4. Add OS-specific stow packages if needed
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

### 1Password Socket (Linux)
- **Issue**: No automatic socket creation on Linux
- **Impact**: User must manually configure or script errors out
- **Workaround**: Script provides message but doesn't help user fix it

### Stow Conflicts
- **Issue**: If target files already exist, stow will fail
- **Impact**: Can't install on system with existing configs
- **Workaround**: User must manually backup/remove conflicting files

### Fish Shell Change
- **Issue**: chsh may not work in all environments (containers, etc.)
- **Impact**: Installation "succeeds" but Fish isn't default shell
- **Workaround**: Script provides manual chsh command to run

## Dependencies & Prerequisites

### User Must Install Before Running
- **1Password** (GUI application)
  - Must enable SSH Agent in settings
  - Must add SSH keys to vault
- **curl** - For downloading installer
- **sudo access** (Linux only) - For installing packages and creating symlinks in /usr/local

### Installer Provides
- git, stow, fish, starship, mise, eza, lazygit, lazydocker
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
- **Stow packages mirror structure** - git/.gitconfig becomes ~/.gitconfig
- **Script paths must be portable** - Use $HOME, not absolute paths
- **1Password paths differ by OS** - Check all platforms when modifying
- **Don't add comments to simple helper scripts** - If a 2-line script needs comments, rename it
- **Don't create inline functions for reusable logic** - Create helper scripts instead

### Suggested Improvements (Future Considerations)
- Pre-flight validation that 1Password is installed and configured
- Automatic backup before stowing configs
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
7. Installer ensures helper scripts are in PATH
8. Detects OS and distribution using helper scripts (dotfiles-is-macos, dotfiles-is-linux, etc.)
9. Installs required packages via appropriate package manager
10. Sets up 1Password agent socket and op-ssh-sign symlinks
11. Switches git remote from HTTPS to SSH (for authenticated operations)
12. Stows each config package (creates symlinks to ~/)
13. Adds fish to /etc/shells and sets as default shell
14. Displays success messages with status indicators

## Update Flow

1. User runs `dotfiles-update` or notified by `dotfiles-updates-notify`
2. `dotfiles-check-updates` runs once per day on interactive shell startup
3. Script runs git pull in ~/dotfiles (via SSH after initial setup)
4. Script runs `dotfiles-migrate` to apply any pending migrations
5. Changes are immediately active (symlinks point to updated files)
6. **Note**: New packages or stow packages require re-running `dotfiles-install`

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
