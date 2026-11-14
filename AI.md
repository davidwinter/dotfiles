# AI Context for Dotfiles Project

## Project overview

**Name**: dotfiles  
**Purpose**: Personal configuration management for consistent development environments across macOS, Omarchy (Arch), Ubuntu and WSL  
**Primary technologies**: mise (bootstrap and dotfiles), Bash, Fish shell, 1Password SSH Agent  
**Repository**: davidwinter/dotfiles

Machine setup is declared in the mise config and applied by `mise bootstrap`. The repo moved there from GNU Stow and hand-written bash in November 2026; a little cleanup remains (see "Pending cleanup"). Follow "Changing setup safely" before changing install, update, packages, dotfile linking or the login shell.

### Core goals
1. **One-liner installation** - A new machine is set up with one command
2. **Cross-platform support** - macOS, Omarchy/Arch, Ubuntu and WSL
3. **1Password integration** - SSH keys and git signing through 1Password
4. **Idempotent operations** - Install and update are safe to run any number of times
5. **Minimal prerequisites** - git, curl, mise and (on desktops) 1Password

## Architecture

```
curl | bash  →  bootstrap
                  ├─ clones the repo to ~/dotfiles over HTTPS
                  ├─ checks mise (MISE_MIN_VERSION)
                  ├─ marks existing migrations applied (new machines only)
                  └─ apply_mise_bootstrap → mise bootstrap
                       ├─ system packages and apps   [bootstrap.packages]
                       ├─ dotfile links              dotfile groups + module entries
                       ├─ macOS preferences          [bootstrap.macos.*]
                       ├─ login shell                [bootstrap.user]
                       └─ tools                      [tools]

dotfiles-update  →  git pull → restart from the pulled version → check mise
                    → dotfiles-migrate → apply_mise_bootstrap

dotfiles-doctor  →  readable report built on mise's own status commands
```

`apply_mise_bootstrap` (in `dotfiles-lib.sh`) runs mise with `MISE_CONFIG_DIR` pointing at the repo's copy of the mise config, so it works before `~/.config/mise` is linked, and with `MISE_ENV` from `dotfiles-mise-env`, which selects this machine's config modules.

### Core principles
- **Declare, don't script** - Anything mise can express goes in the mise config; scripts are for what it can't
- **Simplicity over features** - Prefer straightforward solutions over abstractions
- **Explicit over implicit** - Configuration should be obvious and traceable
- **Safe by default** - Scripts use `set -euo pipefail`; mise stops before overwriting existing files
- **Composable tools** - Small, focused helper scripts

### Key design decisions

#### Why mise for setup and linking?
- **Decision**: `mise bootstrap` installs packages, links dotfiles, applies macOS preferences, sets the login shell and installs tools
- **Rationale**: One declarative config; mise only changes what differs, so every run converges a machine to the config, and new files need no migration
- **Trade-off**: Mise is young and changing quickly, so `MISE_MIN_VERSION` gates install and update
- **Implementation**: Each directory under `configs/` (and `scripts/`) is a dotfile group linked into `~` with one symlink per file (`symlink-each`); machine-specific files are entries in `config.dotfiles-<module>.toml` modules

#### Why 1Password SSH Agent?
- **Decision**: Use 1Password for SSH keys and git signing
- **Rationale**: Keys never touch disk, biometric approval, works across devices
- **Trade-off**: Requires 1Password and a little manual setup
- **Implementation**: SSH agent socket, and `op-ssh-sign` through the `git-ssh-sign` wrapper

#### Why Fish?
- **Decision**: Fish is the login shell on every machine, Omarchy included
- **Rationale**: Better defaults, modern syntax, good completion
- **Trade-off**: Not POSIX; scripts stay in bash. On Omarchy, fish logins don't get `OMARCHY_PATH`, so run `bash -lc omarchy-update` over SSH

#### Why keep `dotfiles-doctor`?
- `mise bootstrap status --missing` always fails on Omarchy (its system mise config lists about 30 install-on-first-use tools, which status counts as missing) and doesn't say which file in a group is missing. The doctor is a filtered, readable view of mise's status plus 1Password and git checks.

## Project structure

```
dotfiles/
├── bootstrap                 # Entry point for the curl one-liner
├── configs/                  # Config packages, each mirroring $HOME
│   ├── fish/  git/  ssh/  starship/  vim/  nano/  hushlogin/  claude/  zed/
│   ├── git-1password/        # Machines with 1Password (dotfiles-1password module)
│   ├── git-wsl/              # WSL (dotfiles-wsl module)
│   ├── omarchy/              # Omarchy (dotfiles-omarchy module)
│   ├── ghostty-macOS/        # macOS (dotfiles-macos module)
│   └── mise/.config/mise/
│       ├── config.toml               # Packages, dotfile groups, macOS preferences, login shell, tools
│       └── config.dotfiles-*.toml    # Machine-specific modules, chosen by MISE_ENV
├── scripts/.local/           # Linked by the "scripts" dotfile group
│   ├── bin/
│   │   ├── dotfiles-update, dotfiles-doctor
│   │   ├── dotfiles-check-updates, dotfiles-updates-notify
│   │   ├── dotfiles-migrate, dotfiles-add-migration, dotfiles-migrations-status
│   │   ├── dotfiles-mise-env                 # Prints this machine's mise modules
│   │   └── dotfiles-is-*, dotfiles-has-*, dotfiles-detect-linux-distro
│   └── lib/dotfiles-lib.sh   # Shared functions
├── migrations/               # One-off fixes for existing machines
├── AI.md
└── README.md
```

### How config packages are linked
- Each directory under `configs/` mirrors where its files go: `configs/git/.gitconfig` is linked to `~/.gitconfig`
- Packages for every machine are dotfile groups in `config.toml`, each with `root` and `mode = "symlink-each"`: one relative symlink per file, directories kept real, so files apps create there (`known_hosts`, `fish_variables`, agent sockets) stay out of the repo. `.gitignore` files are excluded in `fish` and `ssh`
- Packages for some machines are individual `[dotfiles]` file entries in a `config.dotfiles-<module>.toml` module, because a module's `dotfile_groups` list would replace the shared one rather than add to it
- The `mise` group links mise's own config files, including the modules
- A new file in the repo is linked on the next `dotfiles-update`
- Mise refuses to link over an existing real file and stops before changing anything

## Key files

**`bootstrap`** - The one-liner's entry point. Takes an optional repository argument (default `davidwinter/dotfiles`), clones it over HTTPS to `~/dotfiles` (or reuses an existing clone), checks mise, marks existing migrations applied on a new machine (before mise runs, so a later update doesn't run them even if the install stops partway), then runs `apply_mise_bootstrap`. Safe to run again on an installed machine. Prerequisite: git.

**`dotfiles-update`** - Pulls, then restarts itself from the version just pulled (bash keeps running the old copy otherwise). Stops before changing anything if mise is missing or older than `MISE_MIN_VERSION`. Then runs `dotfiles-migrate` and `apply_mise_bootstrap`.

**`dotfiles-doctor`** - Reports mise version and modules, packages, 1Password (agent socket on macOS and Linux; on WSL the Windows signing tool from `config-wsl` and `ssh-add.exe`), whether the dotfiles repo pushes over SSH, each dotfile group and module file (naming any file that isn't linked), the login shell and migrations.

**`dotfiles-check-updates`** / **`dotfiles-updates-notify`** - Once a day on interactive shell start, fetch and report whether updates are available.

**`dotfiles-lib.sh`** - Shared functions for `bootstrap`, `dotfiles-update` and `dotfiles-doctor`: `check_mise_ready`, `dotfiles_mise`, `apply_mise_bootstrap`, and the doctor's `check_*` functions. `stow_configs_for_host` and `install_mise_tools` are stand-ins for update scripts from before the mise migration; remove them once every machine has updated (see "Pending cleanup").

### Configuration files

**`.gitconfig`** - User, signing key and aliases. Includes `~/.config/git/config-1password` and `~/.config/git/config-wsl` (git ignores a missing include). A `pushInsteadOf` rule pushes the dotfiles repo over SSH while it's cloned and pulled over HTTPS.

**`.ssh/config`** - While an SSH login has forwarded an agent (fish keeps `~/.ssh/agent.sock` pointing at it), every terminal uses it; otherwise the local 1Password agent (`~/.1password/agent.sock`).

**`config.fish`** - Adds `~/.local/bin` to `PATH`, sets `MISE_ENV` from `dotfiles-mise-env`, activates mise, keeps `~/.ssh/agent.sock` pointing at the latest forwarded agent in SSH logins, starts starship when installed, and on WSL aliases `ssh` to `ssh.exe`.

**`config-wsl`** (git-wsl) - Git on WSL uses `ssh.exe`, a WSL-specific signing key, and Windows' `op-ssh-sign-wsl`.

## Machine modules

`dotfiles-mise-env` prints this machine's modules; fish sets `MISE_ENV` from it, and bootstrap, update and doctor pass it to mise.

| Module | Applies when (detected by) | Holds |
|---|---|---|
| `dotfiles-macos` | macOS (`dotfiles-is-macos`) | Ghostty config |
| `dotfiles-<distro>`, e.g. `dotfiles-arch`, `dotfiles-ubuntu` | Linux (`dotfiles-detect-linux-distro`; derivatives map via `ID_LIKE`) | Nothing yet |
| `dotfiles-omarchy` | Omarchy (`dotfiles-is-omarchy`) | Hyprland `bindings.lua` and `autostart.lua`; the bar layout (`shell-bar.json`, merged into `shell.json`) |
| `dotfiles-wsl` | WSL (`dotfiles-is-wsl`) | `config-wsl` |
| `dotfiles-1password` | The 1Password app is installed (`dotfiles-has-1password`), however you're connected | `config-1password`, `git-ssh-sign`, the `op-ssh-sign` link, the macOS agent socket link |

Naming a module with no file is harmless. Prefer an `os` key or a package-manager prefix in the shared config; use a module only when nothing there can express the condition. Within a module, `variants = [{ os = "macos" }]` limits an entry to one OS (variants can change an entry's target but not its source, so use one named entry per OS when the source differs).

### Adding a module
1. Make `dotfiles-mise-env` print it when the machine qualifies, using a `dotfiles-is-*` or `dotfiles-has-*` helper.
2. Create `config.dotfiles-<name>.toml`. It's linked into `~/.config/mise`, so mise trusts it automatically.

## Platform notes

- **macOS** - Homebrew packages and casks, Mac App Store apps via `mas:` entries, macOS preferences. `~/.local/bin/op-ssh-sign` links to `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`; `~/.1password/agent.sock` links to 1Password's socket in its app container
- **Arch / Omarchy** - pacman packages. `~/.local/bin/op-ssh-sign` links to `/opt/1Password/op-ssh-sign`; 1Password creates the agent socket itself. Omarchy also ships its own system mise config (`/etc/mise/conf.d/`), whose AI tools install on first use
- **Ubuntu** - apt packages; same 1Password links as Arch
- **WSL** - Modules `dotfiles-ubuntu,dotfiles-wsl`; packages from apt. 1Password runs on Windows: ssh is aliased to `ssh.exe`, and git signs through `op-ssh-sign-wsl` (path hardcoded in `config-wsl`)

## Coding standards

### Bash
```bash
#!/usr/bin/env bash
set -euo pipefail
```

### Portability (macOS and Linux)
Every script and migration must run unchanged on macOS, Ubuntu, Arch and WSL. macOS ships **bash 3.2** and **BSD** userland, so:
- **No bash 4+ features**: no `declare -A`/`local -A`, `mapfile`/`readarray`, `${var,,}`/`${var^^}`, `declare -n`, `&>>` or `|&`. Use newline-separated strings or plain indexed arrays
- **Empty arrays under `set -u`**: `"${arr[@]}"` on an empty array is an "unbound variable" error in bash 3.2. Guard with a length check
- **GNU vs BSD flags differ**: `sed -i` (BSD needs `sed -i ''`), `stat -c` vs `stat -f`, `date -d`, `readlink -f`, `grep -P`, `find -printf`. Prefer portable forms, or try GNU then fall back to BSD
- **Test on macOS** (or review against this list) before pushing anything that runs during `dotfiles-update`, since a failing migration blocks updates

### Naming and organisation
- Executables: lowercase with hyphens, no extension, `dotfiles-` prefix (`dotfiles-is-macos`, `dotfiles-mise-env`)
- Helper scripts: `dotfiles-is-*` / `dotfiles-has-*` answer by exit code; `dotfiles-detect-*` and `dotfiles-mise-env` print a value
- Constants in UPPERCASE (`DOTFILES_DIR`, `MISE_MIN_VERSION`), locals in lowercase
- Small helper scripts over sourced functions for anything fish or other scripts reuse; library functions for logic shared by bootstrap, update and doctor
- Comment the why, not the what

### Helper script usage
```bash
if dotfiles-is-macos; then ...; fi        # bash
if dotfiles-is-wsl; ...; end              # fish
MISE_ENV="$(dotfiles-mise-env)"           # capture output
```

## Changing setup safely

Machines update at different times, and one may not have updated for months. These rules keep every machine working whatever state it starts from.

1. **Every change arrives through `dotfiles-update`.** It pulls, restarts itself from the version just pulled, checks mise, runs migrations, then runs `mise bootstrap`. Migrations run before mise, so they can prepare a machine for the config that follows.
2. **A machine may be far behind.** It runs every pending migration in order, against the current repo. So migrations must be safe to run more than once, check before they act, and use plain commands. Anything an old migration calls (a helper script, stow) stays until no machine still needs to run it.
3. **Old update scripts run once.** The first update after a change to `dotfiles-update` still runs the machine's old copy, which sources the new `dotfiles-lib.sh`. Keep any library function an old update script calls (as stand-ins) until every machine has updated.
4. **New machines start from the current state.** `bootstrap` marks every existing migration applied, so a change must also work for a fresh install.
5. **An old mise stops the update, not the machine.** `MISE_MIN_VERSION` in `dotfiles-lib.sh` is the oldest supported mise; `dotfiles-update` stops before changing anything if a machine's mise is missing or older. (mise's own `min_version` setting isn't used: its warning appears on every mise command, including every new shell.)
6. **Try one machine first.** Run `mise bootstrap --dry-run` before updating, start with one machine (usually penny), and revert the commits to roll back.
7. **Declare removals before writing migrations** (see "Migrations").

## Migrations

Migrations are one-off scripts that move existing machines from an old state to the current one. New machines never run them: `bootstrap` marks every existing migration applied.

- Files: `migrations/<timestamp>.sh`, created with `dotfiles-add-migration` (timestamp of the last commit)
- Run by `dotfiles-update` through `dotfiles-migrate`, in order, each with `bash -euo pipefail`; no shebang or boilerplate needed
- State: empty marker files in `~/.local/state/dotfiles/migrations/` (a `skipped/` subdirectory for ones skipped after a failure); `dotfiles-migrations-status` lists them
- On failure, the runner asks whether to skip and continue or stop

**Prefer declaring a removal in the mise config over writing a migration.** Mise doesn't remove what a config stops declaring, but it removes what you declare as gone, on every machine at its next update:
- A file or link: a `[dotfiles]` entry with `mode = "absent"`, optionally limited to one OS with `variants = [{ os = "macos" }]`:
  ```toml
  [dotfiles]
  "~/.config/old-tool/config" = { mode = "absent" }
  ```
- Links to files deleted from a dotfile group: `mise bootstrap --prune-dotfiles` (or `mise dot apply --prune`)
- A LaunchAgent mise created: `mise bootstrap services remove <name>`; deleting its declaration alone leaves it loaded
- A package: an entry declared absent in `[bootstrap.packages]`

Like a migration, a removal entry only needs to stay until every machine has updated past it; then delete it.

**When you still need a migration:** removing something the config can't express (a leftover from the stow-era setup, or something outside your home directory that mise didn't create), or a one-off structural change mise can't converge by itself.

**Writing one:**
1. Make it safe to run more than once, and check before acting
2. A machine may run it months late, against the current repo: don't rely on `dotfiles-*` commands or library functions that may change; use plain commands
3. Use `$DOTFILES_DIR`, not hardcoded paths
4. Print what it changed, and keep it to one logical change
5. Follow the portability rules above

**Not needed for:** changing config values, or adding files, packages, dotfile groups, tools or macOS preferences (mise applies them on the next update).

## Packages and tools

System packages and apps are under `[bootstrap.packages]` in `config.toml`; command-line tools are under `[tools]`.
- One entry per package manager, with that manager's package name: `"pacman:fish" = "latest"`, `"apt:fish" = "latest"`, `"brew:fish" = { os = "macos" }`. Mise skips entries for a manager that isn't installed
- `"latest"` means "make sure it's installed"; mise doesn't upgrade it
- Tools set to `latest` only take releases at least 7 days old (`minimum_release_age` in `[settings]`), so a bad or compromised release is usually pulled before it arrives. Add a tool to `minimum_release_age_excludes` to keep it current (Claude Code is excluded)
- Give Homebrew and `mas:` entries `os = "macos"`
- On macOS, git and curl come with the system, so they have no entries
- Check a Homebrew cask downloads from the vendor (`brew info --cask <name>`) before adding it. Mac App Store apps use `"mas:<app id>"` and need the `mas` tool (`brew:mas`) and an App Store sign-in

## 1Password

**SSH agent** - `~/.ssh/config` uses the forwarded agent while an SSH login has one, otherwise `~/.1password/agent.sock` (linked by mise on macOS, created by 1Password on Linux). WSL uses the Windows agent through `ssh.exe`.

**Git signing** - `gpg.format = ssh`. On machines with the 1Password app, `config-1password` sets `gpg.ssh.program = git-ssh-sign`, which signs with `ssh-keygen` through the forwarded agent while one is live (so the prompt appears on the machine you connected from) and otherwise with `~/.local/bin/op-ssh-sign`, which mise links to 1Password's tool for the OS. Machines without 1Password sign with `ssh-keygen` through a forwarded agent (`ForwardAgent yes` for that host on the connecting machine). WSL uses `op-ssh-sign-wsl` from `config-wsl`.

## Common tasks

### Adding config files
1. For every machine: create `configs/<package>/` mirroring the target paths, then add it to `dotfile_groups` with a `[dotfile_groups.<package>]` table (`root`, `mode = "symlink-each"`) in `config.toml`. A new file in an existing package needs nothing else
2. For some machines: add a `[dotfiles]` entry for each file to the right module
3. Check with `mise bootstrap --dry-run` and `dotfiles-doctor`, then run `dotfiles-update`

### Supporting a new OS or distro
1. Make sure the `dotfiles-is-*` helpers and `dotfiles-mise-env` recognise it
2. Add package entries for its package manager
3. Add 1Password link entries for it in `config.dotfiles-1password.toml` if its paths differ
4. Test on a real machine, including a fresh install

### Raising the minimum mise version
Change `MISE_MIN_VERSION` in `dotfiles-lib.sh` when the config starts relying on a newer mise feature, and check every machine's mise first: older machines stop updating until they upgrade.

## Known issues and quirks

- **Signing keys hardcoded** in `.gitconfig` (and `config-wsl`); no per-machine override yet
- **WSL paths hardcoded**: `config-wsl` includes the Windows username and 1Password's `app/8`; the doctor flags it if the path stops existing
- **Existing files on a new machine**: mise refuses to link over them and stops; move each aside (`mv ~/.gitconfig ~/.gitconfig.bak`) and run the install again
- **Login shell**: `chsh` may fail in containers; the doctor reports the login shell
- **Omarchy's mise tools**: on every update mise looks up versions for Omarchy's install-on-first-use tools, and a slow site (for example `cursor.com`) delays it by up to 30 seconds. `disable_tools` in `[settings]` would stop that for tools you don't use
- **Some macOS settings are manual** (default browser, recent items, Finder sidebar, Spotlight related content, Caps Lock per keyboard); the README lists them

### Pending cleanup
Waiting for sevenofnine (Omarchy), the one machine that hasn't run the mise setup yet. On it: check `mise --version` is 2026.11.6 or newer, run `dotfiles-update` twice (the first run uses its old update script), then `dotfiles-doctor`. Once that's clean:
- Remove the `stow_configs_for_host` and `install_mise_tools` stand-ins from `dotfiles-lib.sh`
- Remove `stow` from `[bootstrap.packages]`
- Remove the `.gitignore` safety nets (root `.gitignore`, `configs/fish/.config/fish/.gitignore`, `configs/ssh/.ssh/.gitignore`) and the matching `exclude` lines in `config.toml`; per-file links mean no app file can land in the repo
- Remove `dotfiles-is-arch`, `dotfiles-is-ubuntu` and `dotfiles-is-ssh-session` (only old migrations call them), with `absent` entries for their links, and from the README
- Optionally delete the old migrations, and the `absent` entry for `dotfiles-install`

### Open items
Not started; each needs a decision first.
- **herdr-core (`hc`) on Linux machines**, so the Herdr app on the Mac can connect to herdr sessions on them. It isn't in mise's registry or on GitHub releases; it's published only at `releases.herdr.dev`. Tested on penny (2026-11) with mise's `http:` backend, which installs and upgrades it, though without checking the published checksum, and its source has no release dates for `minimum_release_age`:
  ```toml
  [tools."http:herdr-core"]
  version = "latest"
  os = ["linux"]
  version_list_url = "https://releases.herdr.dev/core/latest.json"
  version_json_path = ".version"
  url = "https://releases.herdr.dev/core/{{ version }}/herdr-core-linux-{{ arch(x64='x86_64', arm64='aarch64') }}.tar.gz"
  postinstall = 'ln -sf herdr-core "$MISE_TOOL_INSTALL_PATH/hc"'
  ```
  After an upgrade, a running server stays on the old version until `hc update --from "$(mise which herdr-core)"` or a restart; terminals survive either way
- **GitHub secret scanning and push protection** for this public repo: switched on in the repo's Settings → Security (only the owner can)
- **An allowed signers file**, so `git log --show-signature` verifies commits locally without passing `gpg.ssh.allowedSignersFile` each time
- **Run the macOS CI job only when scripts or migrations change**, if GitHub's macOS runner capacity keeps cancelling it

From a project review (2026-10-03). Done: pulling over HTTPS (no 1Password prompt to fetch), the daily check recording the day before it fetches and giving up on a stalled fetch, and `dotfiles-check-updates` comparing behind and ahead counts and handling a branch with no upstream. Considered and declined for now:
- **Fetching in the background**, so the first shell of the day never waits on `git fetch`. Offline, the check now fails at once and doesn't repeat until the next day, which covers most of the cost.
- **Fish built-ins instead of the helpers in `config.fish`** (`command -q`, `uname`, a `/proc/version` check, and computing `MISE_ENV` only when unset). It would cut shell startup on penny from about 120ms to about 60ms, at the cost of the macOS and WSL checks living in two places.

## Testing

- CI (`.github/workflows/ci.yml`) runs on every push: shellcheck at warning level on the scripts and migrations, `fish --no-execute` on the fish config, the helpers on Linux, and on macOS a run of the scripts, library and recent migrations under the system bash 3.2. Keep it green: fix new shellcheck warnings rather than lowering the level
- Beyond CI, changes are tested on real machines (penny: Omarchy; a Mac; WSL)
- Before changing setup, run `mise bootstrap --dry-run` and test risky changes in a throwaway home: `HOME`, `MISE_DATA_DIR`, `MISE_STATE_DIR` and `MISE_CACHE_DIR` pointed at a temporary directory (and `XDG_CONFIG_HOME` unset)
- After a change: `dotfiles-update`, then `dotfiles-doctor`
- A possible CI addition: a mise config check (`mise bootstrap --dry-run` failing on unknown-key warnings)

## AI assistant guidelines

1. **Keep every platform working** - macOS, Omarchy/Arch, Ubuntu and WSL
2. **Preserve the one-liner install**
3. **Keep install and update idempotent**, and follow "Changing setup safely": changes arrive through `dotfiles-update` and must work for a machine that hasn't updated for a while
4. **Prefer mise config over scripts**, and declared removals over migrations
5. **Minimal dependencies** - don't add required tools without strong justification
6. **Update README.md** for user-facing changes and **AI.md** for architecture or convention changes
7. **No summary markdown files** - don't create `PHASE-X-SUMMARY.md` or similar
8. **Pitfalls**: Homebrew's prefix differs between Apple Silicon and Intel; never `sudo` Homebrew; 1Password paths differ by OS and on WSL
