#!/usr/bin/env bash
# Rows for the config file picker (label<TAB>path<TAB>hint<TAB>display).
#
#   config_list.sh rows
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# shellcheck source=fzf_rows.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/fzf_rows.sh"

_config_collect_row() {
  local label="$1" path="$2" hint="${3:-}" force="${4:-}"
  case "$path" in
    "~/"*) path="${HOME}/${path#~/}" ;;
    "~") path="$HOME" ;;
  esac
  if [ "$force" = always ] || [ -f "$path" ]; then
    printf '%s\t%s\t%s\n' "$label" "$path" "$hint"
  fi
}

_config_collect_rows() {
  _config_collect_row "Shell env & theme" "$HOME/.local.sh" "TERMINAL, ZSH_THEME, EDITOR, secrets" always
  _config_collect_row "Alias overrides" "$HOME/.bash_aliases" "Override repo aliases (bash & zsh)" always
  _config_collect_row "tmux" "$HOME/.tmux.conf" "Multiplexer layout & plugins"
  _config_collect_row "Alacritty" "$HOME/.config/alacritty/alacritty.toml" "Terminal emulator"
  _config_collect_row "Kitty" "$HOME/.config/kitty/kitty.conf" "Terminal emulator"
  _config_collect_row "WezTerm" "$HOME/.config/wezterm/wezterm.lua" "Terminal emulator"
  _config_collect_row "Kitty colors" "$HOME/.config/kitty/colors.conf" "Gogh theme (colorscheme)"
  _config_collect_row "WezTerm colors" "$HOME/.config/wezterm/colors.lua" "Gogh theme (colorscheme)"
}

_config_rows() {
  local tmp label path hint display max=0 len
  tmp=$(mktemp)
  # shellcheck disable=SC2061
  trap 'rm -f "$tmp"' RETURN

  _config_collect_rows >"$tmp"

  while IFS=$'\t' read -r label path hint; do
    len=${#label}
    (( len > max )) && max=$len
  done <"$tmp"

  while IFS=$'\t' read -r label path hint; do
    display=$(_fzf_row_display "$max" "$label" "$hint")
    printf '%s\t%s\t%s\t%s\n' "$label" "$path" "$hint" "$display"
  done <"$tmp"
}

case "${1:-}" in
  rows) _config_rows ;;
  *)
    printf 'Usage: %s rows\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
