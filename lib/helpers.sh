#!/usr/bin/env bash

RESET="\033[0m"
BOLD="\033[1m"
# shellcheck disable=SC2034
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"

# Terminal values gogh accepts (the colorscheme function passes TERMINAL straight
# to gogh's apply-colors.sh). Mirror of that script's dispatch — keep in sync if
# gogh adds terminals. install.sh only ships config templates for the first three.
COLORSCHEME_TERMINALS="alacritty kitty wezterm konsole gnome-terminal mate-terminal \
xfce4-terminal tilix guake foot terminator mintty iTerm.app pantheon-terminal \
io.elementary.terminal kmscon linux termux"

# Returns 0 when $1 is a terminal gogh/colorscheme can theme. Matches gogh's
# prefix cases for gnome-terminal* and io.elementary.t* as well.
# Usage: is_colorscheme_terminal <name>
is_colorscheme_terminal() {
  local term="${1:-}"
  [[ -z "$term" ]] && return 1
  case "$term" in
    gnome-terminal*|io.elementary.t*) return 0 ;;
  esac
  case " ${COLORSCHEME_TERMINALS} " in
    *" ${term} "*) return 0 ;;
    *) return 1 ;;
  esac
}

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

# Copy a config from a repo template into the user's home or config directory
# (real file, not a symlink). Keeps personal edits out of the dotfiles repo.
#
# Legacy installs symlinked configs into this repo; on migrate we:
#   1. Back up the symlink target to <dest>.old (so nothing is lost)
#   2. Remove the symlink and write a real file at <dest>
#   3. Never touch an existing regular file at <dest> (already migrated)
#
# Usage: install_config_from_template <dotfiles_dir> <example_rel> <dest_path> [font_family]
install_config_from_template() {
  local dotfiles="$1"
  local example_rel="$2"
  local dest="$3"
  local font_family="${4:-}"
  local example="$dotfiles/$example_rel"
  local legacy_src

  [ -f "$example" ] || return 1
  mkdir -p "$(dirname "$dest")"

  _apply_font_if_needed() {
    if [[ -n "$font_family" ]] && [[ -f "$dest" ]]; then
      # shellcheck source=fonts.sh
      source "$dotfiles/lib/fonts.sh"
      substitute_font_placeholder "$dest" "$font_family"
    fi
  }

  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo -e "  ${GREEN}✓${RESET}  $dest already exists (local file) — skipping."
    return 0
  fi

  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$dotfiles"* ]]; then
    legacy_src="$(readlink "$dest")"
    [[ "$legacy_src" != /* ]] && legacy_src="$(dirname "$dest")/$legacy_src"

    if [ -f "$legacy_src" ]; then
      cp "$legacy_src" "${dest}.old"
      echo -e "  ${GREEN}✓${RESET}  Backed up previous config to ${DIM}${dest}.old${RESET}"
      rm "$dest"
      cp "$legacy_src" "$dest"
    else
      echo -e "  ${YELLOW}⚠${RESET}  Symlink target missing (${legacy_src}) — using template."
      rm "$dest"
      cp "$example" "$dest"
      _apply_font_if_needed
    fi
    echo -e "  ${GREEN}✓${RESET}  Replaced dotfiles symlink with local copy at $dest"
    return 0
  fi

  if [ ! -e "$dest" ]; then
    cp "$example" "$dest"
    _apply_font_if_needed
    echo -e "  ${GREEN}✓${RESET}  Created $dest from template."
    return 0
  fi

  echo -e "  ${YELLOW}⚠${RESET}  $dest exists and is not a dotfiles symlink — skipping."
  return 0
}

# Remove a legacy config file left in the repo after migrating to a local copy.
# Backs up the repo file to <path>.old before deleting. Usage:
#   remove_legacy_repo_copy <repo_file> <local_dest>
remove_legacy_repo_copy() {
  local repo_file="$1"
  local dest="$2"

  [ -f "$repo_file" ] || return 0
  [ -f "$dest" ] && [ ! -L "$dest" ] || return 0

  cp "$repo_file" "${repo_file}.old"
  rm -f "$repo_file"
  echo -e "  ${GREEN}✓${RESET}  Removed legacy repo copy ${repo_file} (backed up to ${repo_file}.old)."
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

# Returns 0 (proceed) when the user confirms, or when CONFIRM_INTERACTIVE is not
# set (non-interactive mode assumes yes). Set CONFIRM_INTERACTIVE=true to prompt.
# Usage: confirm_yes "prompt text"
confirm_yes() {
  local prompt="$1"
  if [[ "${CONFIRM_INTERACTIVE:-false}" == true ]]; then
    ask_yn "$prompt"
    [[ $REPLY =~ ^[Yy]$ ]]
  else
    return 0
  fi
}

# Remove a symlink into dotfiles_dir and restore a pre-install ${dest}.old if present.
# Usage: uninstall_symlink_if_mine <dotfiles_dir> <dest>
uninstall_symlink_if_mine() {
  local dotfiles="$1"
  local dest="$2"

  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$dotfiles"* ]]; then
    rm "$dest"
    echo -e "  ${GREEN}✓${RESET}  Removed symlink ${dest}"
    if [ -f "${dest}.old" ]; then
      mv "${dest}.old" "$dest"
      echo -e "  ${GREEN}✓${RESET}  Restored pre-install config from ${dest}.old"
    fi
    return 0
  fi

  if [ -e "$dest" ]; then
    echo -e "  ${DIM}—${RESET}  ${dest} is not a dotfiles symlink — skipping."
  else
    echo -e "  ${DIM}—${RESET}  ${dest} not found — skipping."
  fi
}

# Remove a copied (or legacy symlinked) config file, backing up to <dest>.uninstall.old.
# Usage: uninstall_copied_config <dotfiles_dir> <dest>
uninstall_copied_config() {
  local dotfiles="$1"
  local dest="$2"
  local legacy_src

  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$dotfiles"* ]]; then
    legacy_src="$(readlink "$dest")"
    [[ "$legacy_src" != /* ]] && legacy_src="$(dirname "$dest")/$legacy_src"
    if [ -f "$legacy_src" ]; then
      cp "$legacy_src" "${dest}.uninstall.old"
    fi
    rm "$dest"
    echo -e "  ${GREEN}✓${RESET}  Removed symlink ${dest} (backup at ${dest}.uninstall.old)"
    return 0
  fi

  if [ -f "$dest" ]; then
    cp "$dest" "${dest}.uninstall.old"
    rm "$dest"
    echo -e "  ${GREEN}✓${RESET}  Removed ${dest} (backup at ${dest}.uninstall.old)"
    return 0
  fi

  echo -e "  ${DIM}—${RESET}  ${dest} not found — skipping."
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
# Optional third argument is the default when the user presses Enter.
# Usage: ask_choice "prompt text" <max> [default]; result in $REPLY
ask_choice() {
  local prompt="$1"
  local max="$2"
  local default="${3:-}"
  local hint="[1-${max}]"
  while true; do
    if [[ -n "$default" ]]; then
      hint="[1-${max}, default ${default}]"
    fi
    read -p "   ${prompt} $(printf '\033[2m')${hint}$(printf '\033[0m'): " -n 1 -r; echo
    if [[ -z "$REPLY" && -n "$default" ]]; then
      REPLY="$default"
    fi
    if [[ "$REPLY" =~ ^[1-9]$ ]] && (( REPLY >= 1 && REPLY <= max )); then
      return
    fi
    echo -e "  ${YELLOW}⚠${RESET}  Please enter a number between ${BOLD}1${RESET} and ${BOLD}${max}${RESET}."
  done
}
