# Home

Configuration for macOS and NixOS.

## Mac Setup

```bash
git clone <https-repo-url>
cd home
./mac/install
```

This will:
- Install Homebrew (if not present)
- Install packages from `mac/Brewfile` (CLI tools and GUI apps)
- Symlink config files from `dotfiles/` for fish, bash, zsh, git, ghostty, direnv, gh, Claude, SSH, and VS Code
- Install VS Code extensions from `dotfiles/vscode/extensions.txt`
- Enable Touch ID for sudo
- Generate SSH key and add to GitHub (if no key exists)
- Set fish as the default shell
- Back up any existing configs to `<config>.backup`

**Note:** Install Docker separately after setup.

**Claude Code Plugins:** After setup, install plugins manually:
```bash
claude plugin add code-reviewer@marketplace
claude plugin add superpowers@marketplace
```

## NixOS Setup

```bash
bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/nixos/install)"
```

### Nix Profiles

Install:
```bash
nix profile install ./profiles#backend
```

Update:
```bash
nix profile upgrade ./profiles#backend
```

Initialize cache example:
```bash
nix build --no-link --print-out-paths github:ghostty-org/ghostty#default
```
