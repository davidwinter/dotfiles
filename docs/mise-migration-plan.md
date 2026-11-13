# Moving dotfiles to mise bootstrap

A phased plan to hand machine setup to `mise bootstrap` and mise dotfiles, across Omarchy, macOS, WSL and Ubuntu. Every phase reaches machines through `dotfiles-update`, works on a machine that has skipped earlier phases, and can be rolled back by reverting its commits.

Status: phases 0 and 1 done (verified on penny and the Mac); phase 2 in progress.

## Where it ends up

Mise does the setup. The repo keeps a small set of scripts: the machine detection helpers, a thin update command, and the scripts configs use.

- **All setup is mise config** in `configs/mise/.config/mise/`: tools, system packages, dotfile links, the login shell and macOS preferences.
- **Shared config** lives in `config.toml` and applies everywhere. Tools and packages are limited by OS with an `os` key, or by package manager (`brew:`, `apt:`, `pacman:`), which mise skips where it isn't installed. macOS preferences are skipped on Linux automatically.
- **Machine-specific config** lives in modules: `config.dotfiles-<name>.toml` files that mise loads only when they're listed in `MISE_ENV`.
- **Machines detect themselves.** `dotfiles-mise-env` works out which modules apply, using the `dotfiles-is-*` helpers. Fish sets `MISE_ENV` from it, and so do the install and update commands. There's no per-machine file to write.
- **No trust step.** Module files sit in `~/.config/mise`, linked from the repo, and mise trusts files in its own config directory (tested).

| Module | Applies when | Holds |
|---|---|---|
| `dotfiles-macos` | macOS | Ghostty config, the 1Password agent socket link |
| `dotfiles-arch` | Arch and Arch-based | Nothing yet; reserved so Arch-only items have a home |
| `dotfiles-omarchy` | Omarchy | Hyprland bindings and autostart, Waybar config |
| `dotfiles-ubuntu` | Ubuntu and Ubuntu-based | Nothing yet |
| `dotfiles-wsl` | WSL | Git config pointing at Windows' ssh and 1Password |
| `dotfiles-1password` | 1Password is installed on this machine | Git signing through `git-ssh-sign` |

| Machine | `MISE_ENV` it works out | Mise |
|---|---|---|
| penny (Omarchy) | `dotfiles-arch,dotfiles-omarchy,dotfiles-1password` | 2026.11.6, from Omarchy |
| Mac | `dotfiles-macos,dotfiles-1password` | Homebrew; version to check |
| WSL | `dotfiles-ubuntu,dotfiles-wsl` | mise apt repo; version to check |
| Ubuntu server | `dotfiles-ubuntu` | mise apt repo |

The `dotfiles-1password` module depends only on whether 1Password is installed, not on how you're connected. On penny, which is used both at the desk and over SSH, ssh and `git-ssh-sign` already choose per use: the forwarded agent while connected, penny's own 1Password otherwise.

Day to day:

| Command | Does |
|---|---|
| `dotfiles-update` | Pull the repo, run any pending migrations, then `mise bootstrap` |
| `mise bootstrap status --missing` | Show anything not in place |
| `mise bootstrap --dry-run` | Preview what a run would change |
| `mise dot status` | Dotfile links only |

What stays as scripts: `bootstrap` (the curl one-liner), `dotfiles-update`, `dotfiles-migrate` and its migrations, the `dotfiles-is-*` and `dotfiles-has-*` helpers, `dotfiles-mise-env`, and `git-ssh-sign`. Everything else in `scripts/` retires, along with `dotfiles.json`, `system/` and stow.

## Moving machines safely

Machines update at different times, and one might skip several phases in a single update. These rules keep every machine working whatever state it starts from.

1. **Every change arrives through `dotfiles-update`.** It runs in a fixed order: pull, run migrations, link configs (stow until phase 3, then only the mise package), run `mise bootstrap`. Migrations come before mise, so they can prepare a machine for the config that follows.
2. **The update runs the version it just pulled.** Today an update keeps running the old copy of itself after pulling, so a change to the update steps only takes effect on the following update. Phase 0 makes it restart itself after pulling, so each phase's new steps run in the same update that delivers them.
3. **Any phase can be skipped to.** A machine several phases behind runs every pending migration in order, against the current repo. So migrations must be safe to run more than once, must check before they act, and must use plain commands rather than `dotfiles-*` scripts that a later phase might remove. Each phase is checked against a machine coming straight from phase 0.
4. **Fresh installs land on the latest state.** Each phase updates the install path in the same commits. A new machine installs straight into the current state, and the installer marks every existing migration as applied, as it does today.
5. **An old mise stops the update, not the machine.** `MISE_MIN_VERSION` in `dotfiles-lib.sh` sets the oldest supported mise. If a machine's mise is missing or older, `dotfiles-update` stops before running migrations or changing anything, and says which version is needed. Raise it when the config starts relying on a newer mise feature. (mise's own `min_version` setting isn't used, because its warning appears on every mise command, including every new shell.)
6. **Links move from stow to mise without being recreated.** Mise's relative links match stow's, so mise treats existing stow links as already applied (tested). Moving a package from stow to mise is a config change only, and stow can take the links back if a phase is reverted.
7. **Roll out one machine at a time.** penny first, then the Mac, then WSL. Run `mise bootstrap --dry-run` before the first update of each phase on each machine. Revert the phase's commits to roll back.

## Decisions

- **Login shell on Omarchy (phase 4):** fish, the same as every other machine. When updating Omarchy over SSH, run `bash -lc omarchy-update`, since fish logins don't get `OMARCHY_PATH`.
- **Daily "updates available" notice (phase 6):** kept as it is.

## Phases

### Phase 0: foundations

Put the machinery in place. Nothing a machine ends up with changes.

Work:

- `dotfiles-update` restarts itself after pulling.
- New helpers: `dotfiles-is-omarchy` (`ID=omarchy` in `/etc/os-release`), `dotfiles-has-1password` (the 1Password app on macOS, `/opt/1Password` on Linux), and `dotfiles-mise-env`, which prints the module list.
- `config.fish` sets `MISE_ENV` before activating mise. The install and update commands export it too.
- `MISE_MIN_VERSION` check in install and update (`check_mise_ready`), and a mise section in `dotfiles-doctor`.
- Mise config: `dotfiles.root` pointing at `~/dotfiles/configs`, `relative_symlinks = true`.
- The tools step in install and update becomes `mise bootstrap --yes`. With only tools declared, it does what `mise install` does today.

Migrations: none. The first update after this lands runs the old update script once; every later update gets the new steps.

Exit check: on each machine, `echo $MISE_ENV` shows the expected modules, and `mise bootstrap --dry-run` shows no changes.

Rollback: revert the commits. Nothing on the machines depends on them yet.

### Phase 1: macOS preferences and apps

The first real use of mise bootstrap: macOS `defaults` settings and GUI apps, applied by every update on the Mac.

Work:

- Add preferences to the shared config under `[bootstrap.macos.defaults]`, or mise's Dock, Finder, keyboard and trackpad sections. Linux machines skip them.
- Check them on the Mac with `mise bootstrap macos defaults status`.
- GUI apps as Homebrew casks in `[bootstrap.packages]` with `os = "macos"`, after checking each cask downloads from the vendor (`brew info --cask <name>`). Mac App Store apps can use `mas:<app id>`. Firefox is installed this way (verified on the Mac).
- Preferences with no dependable command-line setting (default browser, Apple menu recent items, Finder sidebar Recents, Spotlight related content, and Caps Lock as Escape, which macOS keeps per keyboard) are listed in the README as one-off manual steps.

Migrations: none.

Exit check: the status command shows every preference as applied on the Mac.

Things to know: mise doesn't restart the Dock or Finder, so some changes show only after `killall Dock Finder` or logging out. Removing a preference from the config doesn't put the old value back; set it to the value you want instead.

### Phase 2: system packages

Mise installs system packages. Stow still links configs.

Work:

- Move the packages from `dotfiles.json` and `system/core-packages.json` into `[bootstrap.packages]`, with each manager's own name: `pacman:ttf-jetbrains-mono-nerd`, `apt:fonts-jetbrains-mono`, `brew-cask:font-jetbrains-mono-nerd-font`, and so on.
- Keep `stow` and `jq` in the list until phase 6, since the remaining scripts use them.
- On macOS, git, curl and jq come with the system, so they have no Homebrew entries.
- The installer installs packages first, with mise pointed at the repo's copy of the config (`MISE_CONFIG_DIR`), because stow, which links that config, is itself one of the packages.
- `dotfiles-doctor` lists package state from `mise bootstrap packages status`, and `dotfiles-validate` only checks configs.

Migrations: none. The packages are already installed, so mise finds nothing to do.

Removes: `packages` in `dotfiles.json`, `system/core-packages.json`, the package functions in `dotfiles-lib.sh`.

Exit check: `mise bootstrap status --missing` lists nothing on any machine.

Rollback: revert the commits. Installed packages stay installed.

### Phase 3: mise links the dotfiles

Mise links every config. Stow only links the mise config itself, which mise needs before it can run.

Work:

- Shared packages become dotfile groups, listed once in the shared config: git, ssh, fish, starship, hushlogin, nano, vim, claude, zed and the scripts. `.gitignore` is excluded in `fish` and `ssh`.
- Machine-specific files become individual entries in their module, seven in all: omarchy's 3, git-1password's 2, ghostty's 1 and git-wsl's 1. Modules can't each add groups, because a later module's group list replaces earlier ones; individual entries combine (tested).
- Turn on mise's dotfile history before the first apply, so overwriting a conflicting file with `--force` can be undone.
- Remove those packages from `dotfiles.json`, which keeps only `mise`.

Migrations: none if a group can point at `scripts/`, which sits outside `configs/`. If it can't, move `scripts/` into `configs/`, with a migration that removes the old `~/.local/bin/dotfiles-*` links before mise links the new ones.

Removes: `configs` entries in `dotfiles.json` with platforms and traits, the stow conflict prompt, the doctor's per-file link check.

Exit check: `mise dot status` is clean everywhere, and each machine's dry run showed no link changes before the first apply.

Rollback: revert the commits and run `dotfiles-update`. Stow takes the existing links back.

### Phase 4: login shell

Mise sets the login shell.

Work:

- Fish as the login shell in `[bootstrap.user]`, which also adds it to `/etc/shells`.
- To check first: whether `login_shell` can differ per module, and whether mise finds Homebrew's fish on macOS.

Migrations: none. Mise compares and changes the shell itself.

Removes: the `/etc/shells` and login shell functions in `dotfiles-lib.sh`.

Exit check: a fresh SSH login to each machine lands in fish, and `bash -lc omarchy-update` works on penny over SSH.

Risk: changing the login shell over SSH. Keep a second session open and test a new login before closing it.

### Phase 5: remaining setup steps

The last things the installer does by hand become config.

Work:

- 1Password agent socket on macOS: a symlink entry in `dotfiles-macos`.
- `op-ssh-sign`: `git-ssh-sign` calls it from where 1Password installs it, removing the `sudo` link in `/usr/local/bin`.
- Repo remote: a `pushInsteadOf` rule in `.gitconfig` pushes to GitHub over SSH, so the installer no longer rewrites the remote.

Migrations: none needed. Existing machines already have the socket link and an SSH remote, and the old `/usr/local/bin/op-ssh-sign` link is harmless if left.

Removes: the 1Password and git remote functions in `dotfiles-lib.sh`.

Exit check: signed commits work on each machine, at the desk and over SSH.

### Phase 6: retire the old machinery

Remove what mise now does, once every machine has run phases 0 to 5.

Work:

- `bootstrap` clones the repo, links the mise config, sets `MISE_ENV` and runs `mise bootstrap`.
- `dotfiles-update` becomes pull, migrate, `mise bootstrap`.
- Rewrite `README.md` and `AI.md` for the new layout.

Migrations: mise's `--prune-dotfiles` removes links to retired scripts, since a group deployed them. A migration covers anything it misses.

Removes: `dotfiles-install`, `dotfiles-doctor`, `dotfiles-validate`, most of `dotfiles-lib.sh`, `dotfiles.json`, `system/`, and `stow` and `jq` from the packages.

Exit check: a fresh install from the README works on each platform, and `mise bootstrap status --missing` is clean on every machine.

## Risks

- **Mise is changing quickly.** Bootstrap and dotfiles are new, with settings due to be renamed in 2027. `MISE_MIN_VERSION` protects against old versions; read the changelog before raising it.
- **Omarchy decides when mise updates on penny.** If it lags behind `MISE_MIN_VERSION`, updates stop until it catches up.
- **Tested on Linux only.** The module behaviour, trust setting and link handling were tested on penny with mise 2026.11.6. macOS and WSL are first exercised in phases 0 and 1.
- **`mise bootstrap status --missing` always fails on Omarchy.** Omarchy's system mise config lists about 30 tools that install on first use, and status counts them as missing. Exit checks and the doctor need to ignore those tools rather than rely on the command's exit code.
- **`MISE_ENV` applies only where it's set:** fish shells and the install and update commands. Tools stay in the shared config, so anything else that runs mise still finds them.
