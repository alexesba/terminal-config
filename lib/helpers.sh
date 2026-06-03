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

# Returns 0 (true) when running inside WSL (Windows Subsystem for Linux).
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
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
