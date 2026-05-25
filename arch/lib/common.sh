GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
msg() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }

write_if_changed() {
  local target="$1"
  local content="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  printf "%s\n" "$content" > "$tmp_file"
  if [[ ! -f "$target" ]] || ! cmp -s "$tmp_file" "$target"; then
    cp "$tmp_file" "$target"
    rm -f "$tmp_file"
    return 0
  fi
  rm -f "$tmp_file"
  return 1
}

ensure_symlink() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    rm -f "$dest"
    return 0
  fi

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 0
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup_path="${dest}.backup"
    if [[ -e "$backup_path" ]]; then
      backup_path="${dest}.backup.$(date +%s)"
    fi
    mv "$dest" "$backup_path"
  fi

  rm -f "$dest"
  ln -s "$src" "$dest"
}
