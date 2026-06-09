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

# Install a Nerd Font by id (caskaydia|jetbrains|fira|hack).
# Usage: install_nerd_font <id>
install_nerd_font() {
  local id="$1"
  local cask zip_name version url font_dir tmpdir

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

  if [[ "$OSTYPE" =~ ^linux ]] && ! is_wsl; then
    zip_name=$(nerd_font_release_zip "$id") || return 1
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
    fi
    return 0
  fi

  echo -e "  ${YELLOW}⚠${RESET}  Install ${BOLD}$(nerd_font_family "$id")${RESET} manually:"
  echo -e "      ${DIM}brew install --cask ${cask}${RESET}"
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

  if [[ "$OSTYPE" =~ ^linux ]] && ! is_wsl; then
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
