#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }

ask() {
    local prompt="$1"
    local result
    warn "$prompt [y/N] "
    read -r result
    case "$result" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

backup_existing() {
    local path="$1"
    if [[ -e "$path" && ! -L "$path" ]]; then
        local backup_path="${path}.backup"
        if [[ -e "$backup_path" ]]; then
            backup_path="${path}.backup.$(date +%s)"
        fi
        msg "Backing up existing $path to $backup_path"
        mv "$path" "$backup_path"
    fi
}

link() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        msg "ERROR: Missing source file: $src" >&2
        return 1
    fi

    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        return 0
    fi

    backup_existing "$dest"

    if [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    msg "Linking $src -> $dest"
    ln -s "$src" "$dest"
}
