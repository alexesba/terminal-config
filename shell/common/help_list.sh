#!/usr/bin/env bash
# Rows for the unified help menu (label<TAB>action<TAB>hint).
#
#   help_list.sh rows
#
# Actions:
#   bindings | colorscheme | use-terminal
#   edit:<absolute-path>
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

_help_action_row() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3"
}

_help_list_rows() {
  _help_action_row "Show key bindings" "bindings" "Keyboard shortcuts for this dotfiles setup"
  _help_action_row "Color scheme" "colorscheme" "Fuzzy-pick and apply a Gogh theme"
  _help_action_row "Switch terminal" "use-terminal" "Point colorscheme at alacritty, kitty, or wezterm"

  bash "$DOTFILES_DIR/shell/common/config_list.sh" rows | while IFS=$'\t' read -r label path hint; do
    [ -n "$label" ] || continue
    printf 'Edit · %s\tedit:%s\t%s\n' "$label" "$path" "$hint"
  done
}

case "${1:-}" in
  rows) _help_list_rows ;;
  *)
    printf 'Usage: %s rows\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
