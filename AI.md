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
├── local-bin/            # Custom utility scripts (stow package)
│   └── .local/bin/
│       ├── dotfiles-install
│       ├── dotfiles-update
│       ├── dotfiles-check-updates
│       ├── dotfiles-updates-notify
│       # Helper scripts (composable utilities)
│       ├── dotfiles-is-macos
│       ├── dotfiles-is-linux
│       ├── dotfiles-is-wsl
│       ├── dotfiles-is-ubuntu
│       ├── dotfiles-is-archlinux
│       ├── dotfiles-has-command
│       └── dotfiles-detect-linux-distro
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
- Clones repository via HTTPS to ~/dotfiles
- Adds helper scripts to PATH
- Executes dotfiles-install
- No user-specific information hardcoded

**`dotfiles-install`**
- Main installer script, bootstraps entire system
- Detects OS and installs appropriate packages
- Sets up 1Password SSH agent integration
- Stows config packages (creates symlinks)
- Makes Fish the default shell
- Uses helper scripts for OS detection and logic

**`dotfiles-update`**
- Simple git pull to update dotfiles repo
- Should be enhanced to handle new packages/configs

**`dotfiles-check-updates`**
- Checks for uncommitted local changes
- Fetches remote and compares with local
- Reports number of commits behind

**`dotfiles-updates-notify`**
- Runs once per day on shell startup
- Caches last check date
- Provides non-intrusive update notifications

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
- **Location**: `local-bin/.local/bin/dotfiles-*`
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
- We're not using a migration system for updates which can handle tidy up tasks if we make changes, such as changing the location of stow package files for example, or removing packages that are no longer needed
- Stow packages are currently stored in the root of the project directory, rather than within a `configs` or similar directory structure, but we can't change this yet (assumed) without a migration system in place in order to tidy up previous stow configurations
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
6. **Prefer helper scripts over functions** - Extract reusable logic to small scripts in `local-bin/.local/bin/`
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
3. Checks for git and curl (only prerequisites)
4. Clones dotfiles repository to ~/dotfiles via HTTPS
5. Adds ~/dotfiles/local-bin/.local/bin to PATH
6. Executes dotfiles-install from cloned repository
7. Installer detects OS and distribution (using helper scripts)
8. Install required packages via appropriate package manager
9. Set up 1Password agent socket and op-ssh-sign symlinks
10. Stow each config package (creates symlinks)
11. Add fish to /etc/shells and set as default
12. Display success messages with status indicators

## Update Flow

1. User runs `dotfiles-update` or notified by `dotfiles-updates-notify`
2. Script runs git pull in ~/dotfiles
3. Changes are immediately active (symlinks point to updated files)
4. **Note**: New packages or stow packages require manual intervention, or to re-run `dotfiles-install` to ensure new packages and stow configs are applied

## Philosophy on Configuration

- **Explicit is better than implicit** - No hidden magic
- **Portable over optimal** - Works everywhere rather than perfect on one platform
- **Self-documenting over commented** - Well-named scripts and functions over explanatory comments
- **Composable over monolithic** - Small tools that do one thing well
- **Safe over fast** - Rather fail early than silently corrupt
- **Convention over configuration** - Sensible defaults, minimal choices
