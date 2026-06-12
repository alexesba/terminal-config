#!/usr/bin/env bash
# Rows for the config file picker (label<TAB>path<TAB>hint).
#
#   config_list.sh rows
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# Print one picker row when the file exists or $4 is "always".
_config_row() {
  local label="$1" path="$2" hint="${3:-}" force="${4:-}"
  case "$path" in
    "~/"*) path="${HOME}/${path#~/}" ;;
    "~") path="$HOME" ;;
  esac
  if [ "$force" = always ] || [ -f "$path" ]; then
    printf '%s\t%s\t%s\n' "$label" "$path" "$hint"
  fi
}

_config_rows() {
  _config_row "Shell env & theme" "$HOME/.local.sh" "TERMINAL, ZSH_THEME, EDITOR, secrets" always
  _config_row "Alias overrides" "$HOME/.bash_aliases" "Override repo aliases (bash & zsh)" always
  _config_row "tmux" "$HOME/.tmux.conf" "Multiplexer layout & plugins"
  _config_row "Alacritty" "$HOME/.config/alacritty/alacritty.toml" "Terminal emulator"
  _config_row "Kitty" "$HOME/.config/kitty/kitty.conf" "Terminal emulator"
  _config_row "WezTerm" "$HOME/.config/wezterm/wezterm.lua" "Terminal emulator"
  _config_row "Kitty colors" "$HOME/.config/kitty/colors.conf" "Gogh theme (colorscheme)"
  _config_row "WezTerm colors" "$HOME/.config/wezterm/colors.lua" "Gogh theme (colorscheme)"
}

case "${1:-}" in
  rows) _config_rows ;;
  *)
    printf 'Usage: %s rows\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
