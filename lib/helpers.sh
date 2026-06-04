#!/usr/bin/env bash

RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"

# Links $1 (source) to $2 (destination), idempotently:
#   • already correct symlink  → skips
#   • symlink to wrong target  → removes and relinks
#   • regular file/dir         → backs up then links
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo -e "  ${GREEN}✓${RESET}  $dest already linked — skipping."
      return
    else
      echo -e "  ${YELLOW}⚠${RESET}  $dest points elsewhere — relinking."
      rm "$dest"
    fi
  elif [ -e "$dest" ]; then
    echo -e "  ${YELLOW}⚠${RESET}  $dest already exists — backing up as ${DIM}$dest.old${RESET}"
    mv "$dest" "$dest.old"
  fi

  ln -s "$src" "$dest"
  echo -e "  ${GREEN}✓${RESET}  $dest linked."
}

# Copy a terminal-emulator config from a repo template into the user's config
# directory (real file, not a symlink). Gogh and other tools may write into the
# same directory, so a local copy fits better than linking back into the repo.
# Migrates legacy dotfiles symlinks. Never overwrites an existing regular file.
# Usage: install_terminal_emulator_config <dotfiles_dir> <example_rel> <dest_path>
install_terminal_emulator_config() {
  local dotfiles="$1"
  local example_rel="$2"
  local dest="$3"
  local example="$dotfiles/$example_rel"

  [ -f "$example" ] || return 1
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo -e "  ${GREEN}✓${RESET}  $dest already exists (local file) — skipping."
    return 0
  fi

  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$dotfiles"* ]]; then
    cp "$example" "$dest"
    echo -e "  ${GREEN}✓${RESET}  Migrated $dest from dotfiles symlink to local copy."
    return 0
  fi

  if [ ! -e "$dest" ]; then
    cp "$example" "$dest"
    echo -e "  ${GREEN}✓${RESET}  Created $dest from template."
    return 0
  fi

  echo -e "  ${YELLOW}⚠${RESET}  $dest exists and is not a dotfiles symlink — skipping."
  return 0
}

# Returns 0 (true) when running inside WSL (Windows Subsystem for Linux).
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Sets or updates an `export VAR="value"` line in a target file, idempotently.
# Replaces an existing export of the same VAR — including a commented-out
# placeholder like `# export VAR=...` left by the template — otherwise appends.
# Usage: set_env_var <file> <VAR> <value>
set_env_var() {
  local file="$1" var="$2" value="$3" line match
  line="export ${var}=\"${value}\""
  match="^[[:space:]]*#?[[:space:]]*export[[:space:]]+${var}="
  [ -f "$file" ] || touch "$file"
  if grep -qE "$match" "$file"; then
    # -i.bak keeps this portable across BSD (macOS) and GNU sed; | avoids path clashes
    sed -i.bak -E "s|${match}.*|${line}|" "$file" && rm -f "$file.bak"
    echo -e "  ${GREEN}✓${RESET}  ${var} set in $(basename "$file") → ${value}"
  else
    printf '%s\n' "$line" >> "$file"
    echo -e "  ${GREEN}✓${RESET}  ${var} added to $(basename "$file") → ${value}"
  fi
}

# Prompts yes/no and loops until the user enters y or n (case-insensitive).
# Usage: ask_yn "prompt text"; result in $REPLY
ask_yn() {
  local prompt="$1"
  while true; do
    read -p "   ${prompt} $(printf '\033[2m')(y/n)$(printf '\033[0m') " -n 1 -r; echo
    case "$REPLY" in
      [Yy]|[Nn]) return ;;
      *) echo -e "  ${YELLOW}⚠${RESET}  Please enter ${BOLD}y${RESET} or ${BOLD}n${RESET}." ;;
    esac
  done
}

# Prompts a numbered choice and loops until a valid number is entered.
# Usage: ask_choice "prompt text" <max>; result in $REPLY
ask_choice() {
  local prompt="$1"
  local max="$2"
  while true; do
    read -p "   ${prompt} $(printf '\033[2m')[1-${max}]$(printf '\033[0m'): " -n 1 -r; echo
    if [[ "$REPLY" =~ ^[1-9]$ ]] && (( REPLY >= 1 && REPLY <= max )); then
      return
    fi
    echo -e "  ${YELLOW}⚠${RESET}  Please enter a number between ${BOLD}1${RESET} and ${BOLD}${max}${RESET}."
  done
}
