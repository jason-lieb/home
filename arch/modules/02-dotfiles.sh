#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../../dotfiles"

echo "=== Dotfiles Configuration ==="

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

backup_existing() {
    local path="$1"
    if [[ -e "$path" && ! -L "$path" ]]; then
        local backup_path="${path}.backup"
        if [[ -e "$backup_path" ]]; then
            backup_path="${path}.backup.$(date +%s)"
        fi
        echo "Backing up existing $path to $backup_path"
        mv "$path" "$backup_path"
    fi
}

link_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        echo "ERROR: Missing source file: $src" >&2
        return 1
    fi

    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        return 0
    fi

    backup_existing "$dest"

    if [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    echo "Linking $src -> $dest"
    ln -s "$src" "$dest"
}

echo "Linking repository-managed config files..."
ensure_dir "$HOME/.config/fish"
ensure_dir "$HOME/.config/ghostty"
ensure_dir "$HOME/.config/Code/User/snippets"
ensure_dir "$HOME/.config/direnv"
ensure_dir "$HOME/.config/gh"
ensure_dir "$HOME/.npm-packages"
ensure_dir "$HOME/.aws"
ensure_dir "$HOME/.ssh"
ensure_dir "$HOME/.claude"

link_file "$CONFIG_DIR/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
link_file "$CONFIG_DIR/.bashrc" "$HOME/.bashrc"
link_file "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
link_file "$CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$CONFIG_DIR/.gitignore" "$HOME/.gitignore"
link_file "$CONFIG_DIR/.config/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$CONFIG_DIR/.ssh/config" "$HOME/.ssh/config"
link_file "$CONFIG_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
link_file "$CONFIG_DIR/.config/direnv/direnvrc" "$HOME/.config/direnv/direnvrc"
link_file "$CONFIG_DIR/.config/gh/config.yml" "$HOME/.config/gh/config.yml"
link_file "$CONFIG_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
link_file "$CONFIG_DIR/vscode/snippets/typescript.json" "$HOME/.config/Code/User/snippets/typescript.json"
link_file "$CONFIG_DIR/vscode/snippets/typescript.json" "$HOME/.config/Code/User/snippets/typescriptreact.json"
link_file "$CONFIG_DIR/vscode/snippets/typescript.json" "$HOME/.config/Code/User/snippets/javascript.json"
link_file "$CONFIG_DIR/vscode/snippets/typescript.json" "$HOME/.config/Code/User/snippets/javascriptreact.json"
link_file "$CONFIG_DIR/.aws/config" "$HOME/.aws/config"

# ============================================
# VS Code Extensions
# ============================================
EXTENSIONS_FILE="$CONFIG_DIR/vscode/extensions.txt"
if [[ -f "$EXTENSIONS_FILE" ]] && command -v code &>/dev/null; then
    echo "Installing VS Code extensions..."
    INSTALLED_EXTENSIONS="$(code --list-extensions 2>/dev/null || true)"
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        if ! echo "$INSTALLED_EXTENSIONS" | grep -qi "^${ext}$"; then
            code --install-extension "$ext" 2>/dev/null || true
        fi
    done < "$EXTENSIONS_FILE"
fi

# ============================================
# SSH Key Setup
# ============================================
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
    echo ""
    printf "No SSH key found. Enter your email for the SSH key: "
    read -r email_address
    HOSTNAME="$(hostname -s)"
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$email_address" -N "" -f "$SSH_KEY"
    echo "SSH key generated at $SSH_KEY"

    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        echo "Adding SSH key to GitHub..."
        gh ssh-key add "$SSH_KEY.pub" --title "$HOSTNAME"
        echo "SSH key added to GitHub as '$HOSTNAME'"
    else
        echo ""
        echo "To add your SSH key to GitHub, run:"
        echo "  gh auth login"
        echo "  gh ssh-key add $SSH_KEY.pub --title \"$HOSTNAME\""
    fi
else
    echo "SSH key already exists at $SSH_KEY"
fi

# ============================================
# Switch Repo Remote to SSH
# ============================================
REPO_DIR="$SCRIPT_DIR/../.."
CURRENT_REMOTE="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"
if [[ "$CURRENT_REMOTE" == https://github.com/* ]]; then
    SSH_REMOTE="${CURRENT_REMOTE/https:\/\/github.com\//git@github.com:}"
    echo "Switching repo remote to SSH..."
    git -C "$REPO_DIR" remote set-url origin "$SSH_REMOTE"
    echo "Remote updated: $SSH_REMOTE"
fi

# ============================================
# Fish Plugins
# ============================================
if command -v fish &>/dev/null; then
    if ! fish -c "type -q fisher" 2>/dev/null; then
        echo "Installing fisher..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
    fi
    echo "Installing fish plugins..."
    fish -c "fisher install jorgebucaran/nvm.fish" 2>/dev/null || true
fi

# ============================================
# Set Fish as Default Shell
# ============================================
FISH_PATH="/usr/bin/fish"
if [[ "$SHELL" != *"fish"* ]] && [[ -x "$FISH_PATH" ]]; then
    if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "Adding fish to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    echo "Setting fish as default shell..."
    chsh -s "$FISH_PATH"
fi

echo ""
echo "=== Dotfiles Configuration Complete ==="
