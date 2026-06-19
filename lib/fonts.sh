#!/usr/bin/env bash
# Nerd Font catalog and installation for terminal emulator configs.

# Usage: nerd_font_family <id>
# Short family name (name ID 1) — required by Kitty on macOS.
nerd_font_family() {
  case "$1" in
    caskaydia) echo "CaskaydiaCove NFP" ;;
    jetbrains) echo "JetBrainsMono NFM" ;;
    fira)      echo "FiraCode Nerd Font Mono" ;;
    hack)      echo "Hack Nerd Font Mono" ;;
    *)         return 1 ;;
  esac
}

# Usage: nerd_font_family_ui <id>
# Typographic family name — Alacritty and WezTerm on macOS resolve glyphs correctly
# with this name; the short nerd_font_family name can miss icon codepoints.
nerd_font_family_ui() {
  case "$1" in
    caskaydia) echo "CaskaydiaCove Nerd Font Propo" ;;
    jetbrains) echo "JetBrainsMono Nerd Font" ;;
    fira)      echo "FiraCode Nerd Font Mono" ;;
    hack)      echo "Hack Nerd Font Mono" ;;
    *)         return 1 ;;
  esac
}

# Usage: nerd_font_family_for_terminal <id> <terminal>
nerd_font_family_for_terminal() {
  local id="$1" terminal="$2"
  case "$terminal" in
    kitty) nerd_font_family "$id" ;;
    alacritty|wezterm) nerd_font_family_ui "$id" ;;
    *) nerd_font_family "$id" ;;
  esac
}

# Usage: nerd_font_brew_cask <id>
nerd_font_brew_cask() {
  case "$1" in
    caskaydia) echo "font-caskaydia-cove-nerd-font" ;;
    jetbrains) echo "font-jetbrains-mono-nerd-font" ;;
    fira)      echo "font-fira-code-nerd-font" ;;
    hack)      echo "font-hack-nerd-font" ;;
    *)         return 1 ;;
  esac
}

# Zip name on https://github.com/ryanoasis/nerd-fonts/releases (Linux fallback).
# Usage: nerd_font_release_zip <id>
nerd_font_release_zip() {
  case "$1" in
    caskaydia) echo "CascadiaCode" ;;
    jetbrains) echo "JetBrainsMono" ;;
    fira)      echo "FiraCode" ;;
    hack)      echo "Hack" ;;
    *)         return 1 ;;
  esac
}

# Map a config font family back to a font id.
# Usage: nerd_font_id_from_family <family>
nerd_font_id_from_family() {
  case "$1" in
    "CaskaydiaCove NFP"|"CaskaydiaCove Nerd Font Propo") echo "caskaydia" ;;
    "JetBrainsMono NFM"|"JetBrainsMono Nerd Font")       echo "jetbrains" ;;
    "FiraCode Nerd Font Mono"|"FiraCode Nerd Font")       echo "fira" ;;
    "Hack Nerd Font Mono")                                 echo "hack" ;;
    *)                                                     return 1 ;;
  esac
}

# Filename globs (under ~/.local/share/fonts) for Linux installs. One pattern per line.
# Usage: nerd_font_filename_patterns <id>
nerd_font_filename_patterns() {
  case "$1" in
    caskaydia) printf '%s\n' 'CaskaydiaCove*' ;;
    jetbrains) printf '%s\n' 'JetBrainsMonoNerdFont*' ;;
    fira)      printf '%s\n' 'FiraCodeNerdFont*' ;;
    hack)      printf '%s\n' 'HackNerdFont*' ;;
    *)         return 1 ;;
  esac
}

# Read export VAR="value" from ~/.local.sh without sourcing it.
# Usage: custom_export_value <file> <VAR>
custom_export_value() {
  local file="$1" var="$2"
  [[ -f "$file" ]] || return 1
  sed -nE "s/^[[:space:]]*export[[:space:]]+${var}=['\"]([^'\"]*)['\"].*/\1/p" "$file" | head -1
}

# Resolve which Nerd Font install.sh recorded for this machine.
# Usage: resolve_nerd_font_id [~/.local.sh path]
resolve_nerd_font_id() {
  local custom="${1:-}"
  local id family

  [[ -f "$custom" ]] || return 1

  id=$(custom_export_value "$custom" TERMINAL_FONT_ID)
  if [[ -n "$id" ]] && nerd_font_family "$id" &>/dev/null; then
    echo "$id"
    return 0
  fi

  family=$(custom_export_value "$custom" TERMINAL_FONT)
  if [[ -n "$family" ]]; then
    nerd_font_id_from_family "$family"
  fi
}

# Replace {{FONT_FAMILY}} in a copied terminal config file.
# Usage: substitute_font_placeholder <file> <font_family>
substitute_font_placeholder() {
  local file="$1"
  local font="$2"
  local escaped

  [ -f "$file" ] || return 1
  escaped=$(printf '%s\n' "$font" | sed 's/[\/&]/\\&/g')
  sed -i.bak "s|{{FONT_FAMILY}}|${escaped}|g" "$file" && rm -f "$file.bak"
}

# Return 0 when nerd font files for $id exist under ~/.local/share/fonts.
# Usage: nerd_font_installed_p <id>
nerd_font_installed_p() {
  local id="$1" font_dir pattern
  font_dir="${HOME}/.local/share/fonts"
  [[ -d "$font_dir" ]] || return 1
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    if find "$font_dir" -maxdepth 1 -iname "$pattern" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done < <(nerd_font_filename_patterns "$id")
  return 1
}

# True when Nerd Fonts should install to ~/.local/share/fonts (Linux and WSL).
_nerd_font_linux_install_target_p() {
  [[ "${OSTYPE:-}" =~ ^linux ]]
}

# Download and install a Nerd Font into ~/.local/share/fonts.
# Usage: _install_nerd_font_linux <id>
_install_nerd_font_linux() {
  local id="$1" zip_name version url font_dir tmpdir

  zip_name=$(nerd_font_release_zip "$id") || return 1
  if nerd_font_installed_p "$id"; then
    echo -e "  ${GREEN}✓${RESET}  $(nerd_font_family "$id") already in ~/.local/share/fonts — skipping."
    return 0
  fi

  for cmd in curl unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo -e "  ${YELLOW}⚠${RESET}  ${cmd} not found — install ${cmd} and re-run install."
      return 1
    fi
  done

  version="v3.4.0"
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_name}.zip"
  font_dir="${HOME}/.local/share/fonts"
  tmpdir=$(mktemp -d)

  echo -e "  Downloading ${BOLD}${zip_name}${RESET} from Nerd Fonts (${version})…"
  if ! curl -fsSL "$url" -o "${tmpdir}/font.zip"; then
    echo -e "  ${YELLOW}⚠${RESET}  Download failed — install manually: ${url}"
    rm -rf "$tmpdir"
    return 1
  fi

  mkdir -p "$font_dir" "${tmpdir}/extracted"
  unzip -q "${tmpdir}/font.zip" -d "${tmpdir}/extracted"
  find "${tmpdir}/extracted" \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$font_dir/" \;
  rm -rf "$tmpdir"

  if command -v fc-cache &>/dev/null; then
    fc-cache -fv "$font_dir" >/dev/null 2>&1 \
      && echo -e "  ${GREEN}✓${RESET}  Font installed to ${font_dir} (fc-cache updated)." \
      || echo -e "  ${GREEN}✓${RESET}  Font installed to ${font_dir}."
  else
    echo -e "  ${GREEN}✓${RESET}  Font installed to ${font_dir}."
    echo -e "  ${DIM}Install fontconfig and run: fc-cache -fv ${font_dir}${RESET}"
  fi
  return 0
}

# Load helpers.sh when font sync needs terminal config paths (optional).
_ensure_helpers_for_font_sync() {
  declare -f kitty_config_dir >/dev/null 2>&1 && return 0
  local root="${DOTFILES_DIR:-}"
  [[ -n "$root" && -f "$root/lib/helpers.sh" ]] || return 1
  # shellcheck source=helpers.sh disable=SC1091
  source "$root/lib/helpers.sh"
}

# Write the configured font family into kitty.conf or alacritty.toml.
# Usage: update_terminal_font_config <kitty|alacritty> <font_family>
update_terminal_font_config() {
  local terminal="$1" family="$2" file escaped
  [[ -n "$family" ]] || return 1
  _ensure_helpers_for_font_sync || true

  case "$terminal" in
    kitty)
      if declare -f kitty_config_dir >/dev/null 2>&1; then
        file="$(kitty_config_dir)/kitty.conf"
      else
        file="${KITTY_CONFIG_DIRECTORY:-$HOME/.config/kitty}/kitty.conf"
      fi
      [[ -f "$file" ]] || return 0
      if grep -q '{{FONT_FAMILY}}' "$file" 2>/dev/null; then
        substitute_font_placeholder "$file" "$family"
        return 0
      fi
      escaped=$(printf '%s\n' "$family" | sed 's/[\/&]/\\&/g')
      sed -i.bak -E "s|^([[:space:]]*font_family)[[:space:]].*|\\1 ${escaped}|" "$file" \
        && rm -f "$file.bak"
      ;;
    alacritty)
      if declare -f terminal_emulator_config_path >/dev/null 2>&1; then
        file="$(terminal_emulator_config_path alacritty 2>/dev/null || true)"
      else
        file="${HOME}/.config/alacritty/alacritty.toml"
      fi
      [[ -n "$file" && -f "$file" ]] || return 0
      if grep -q '{{FONT_FAMILY}}' "$file" 2>/dev/null; then
        substitute_font_placeholder "$file" "$family"
        return 0
      fi
      escaped=$(printf '%s\n' "$family" | sed 's/[\/&]/\\&/g')
      sed -i.bak -E "s|^family = .*|family = \"${escaped}\"|g" "$file" \
        && rm -f "$file.bak"
      ;;
    *) return 1 ;;
  esac
}

# Apply recorded font id to Kitty / Linux Alacritty configs on WSL.
# Usage: sync_wsl_linux_terminal_fonts <font_id>
sync_wsl_linux_terminal_fonts() {
  local font_id="$1"

  _ensure_helpers_for_font_sync || return 0
  is_wsl || return 0
  wsl_linux_gui_terminal_detected_p || return 0

  if wsl_kitty_detected_p; then
    update_terminal_font_config kitty "$(nerd_font_family_for_terminal "$font_id" kitty)"
  fi
  if wsl_linux_alacritty_p; then
    update_terminal_font_config alacritty "$(nerd_font_family_for_terminal "$font_id" alacritty)"
  fi
}

# Install a Nerd Font by id (caskaydia|jetbrains|fira|hack).
# Usage: install_nerd_font <id>
install_nerd_font() {
  local id="$1"
  local cask

  cask=$(nerd_font_brew_cask "$id") || return 1

  if command -v brew &>/dev/null; then
    if brew list --cask "$cask" &>/dev/null; then
      echo -e "  ${GREEN}✓${RESET}  ${cask} already installed — skipping."
      return 0
    fi
    echo -e "  Installing ${BOLD}${cask}${RESET} via Homebrew…"
    brew install --cask "$cask"
    echo -e "  ${GREEN}✓${RESET}  Font installed. Restart your terminal emulator to pick it up."
    return 0
  fi

  if _nerd_font_linux_install_target_p; then
    _install_nerd_font_linux "$id"
    return $?
  fi

  echo -e "  ${YELLOW}⚠${RESET}  Install ${BOLD}$(nerd_font_family "$id")${RESET} manually:"
  if declare -f is_wsl >/dev/null 2>&1 && is_wsl; then
    echo -e "      ${DIM}Re-run ./install.sh on WSL to install into ~/.local/share/fonts${RESET}"
  else
    echo -e "      ${DIM}brew install --cask ${cask}${RESET}"
  fi
  return 1
}

# Uninstall a Nerd Font by id (brew cask on macOS; files in ~/.local/share/fonts on Linux).
# Usage: uninstall_nerd_font <id>
uninstall_nerd_font() {
  local id="$1"
  local cask font_dir pattern file removed=0

  cask=$(nerd_font_brew_cask "$id") || return 1

  if command -v brew &>/dev/null && brew list --cask "$cask" &>/dev/null; then
    echo -e "  Uninstalling ${BOLD}${cask}${RESET} via Homebrew…"
    brew uninstall --cask "$cask"
    echo -e "  ${GREEN}✓${RESET}  Removed ${cask}."
    return 0
  fi

  if _nerd_font_linux_install_target_p; then
    font_dir="${HOME}/.local/share/fonts"
    if [[ ! -d "$font_dir" ]]; then
      echo -e "  ${DIM}—${RESET}  ${font_dir} not found — skipping."
      return 0
    fi

    while IFS= read -r pattern; do
      [[ -n "$pattern" ]] || continue
      while IFS= read -r -d '' file; do
        rm -f "$file"
        removed=$((removed + 1))
        echo -e "  ${GREEN}✓${RESET}  Removed $(basename "$file")"
      done < <(find "$font_dir" -maxdepth 1 -iname "$pattern" -print0 2>/dev/null)
    done < <(nerd_font_filename_patterns "$id")

    if (( removed > 0 )) && command -v fc-cache &>/dev/null; then
      fc-cache -fv "$font_dir" >/dev/null 2>&1
    elif (( removed == 0 )); then
      echo -e "  ${DIM}—${RESET}  No matching font files in ${font_dir}."
    fi
    return 0
  fi

  echo -e "  ${DIM}—${RESET}  ${cask} not installed via Homebrew — skipping."
  return 0
}

# Uninstall the Nerd Font recorded in ~/.local.sh (install.sh / bootstrap --font).
# Usage: uninstall_recorded_nerd_font [~/.local.sh path]
uninstall_recorded_nerd_font() {
  local custom="${1:-}"
  local id family

  id=$(resolve_nerd_font_id "$custom") || {
    echo -e "  ${DIM}—${RESET}  No TERMINAL_FONT / TERMINAL_FONT_ID in ~/.local.sh — skipping."
    return 0
  }

  family=$(nerd_font_family "$id")
  echo -e "  ${DIM}Font recorded in ~/.local.sh:${RESET} ${family} (${id})"
  uninstall_nerd_font "$id"
}
