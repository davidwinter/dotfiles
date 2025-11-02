# dotfiles

## Dependencies

- 1Password
- curl

## Setup

1. Ensure 1Password is installed.
2. In 1Password, Settings, Developer, ensure that "Use the SSH Agent" is enabled
3. Opt into displaying key names if prompted
4. When prompted, do not update the local `~/.ssh/config` file
5. Run: `curl -fsSL https://raw.githubusercontent.com/davidwinter/dotfiles/main/clone.sh | bash`
