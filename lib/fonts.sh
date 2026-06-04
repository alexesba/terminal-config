#!/usr/bin/env bash
# Nerd Font catalog and installation for terminal emulator configs.

# Usage: nerd_font_family <id>
# Prints the font family name used in terminal config templates.
nerd_font_family() {
  case "$1" in
    caskaydia) echo "CaskaydiaCove Nerd Font Propo" ;;
    jetbrains) echo "JetBrainsMono Nerd Font" ;;
    fira)      echo "FiraCode Nerd Font" ;;
    hack)      echo "Hack Nerd Font Mono" ;;
    *)         return 1 ;;
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
