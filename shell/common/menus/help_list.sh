#!/usr/bin/env bash
# Rows for the unified help menu (label<TAB>action<TAB>hint<TAB>display).
#
#   help_list.sh rows
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

# shellcheck source=../fzf/rows.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/fzf/rows.sh"

_help_collect_rows() {
  _help_collect_row "Show key bindings" "bindings" "Keyboard shortcuts for this dotfiles setup"
  _help_collect_row "Color scheme" "colorscheme" "Fuzzy-pick and apply a Gogh theme"
  _help_collect_row "Switch terminal" "use-terminal" "Point colorscheme at alacritty, kitty, or wezterm"

  bash "$DOTFILES_DIR/shell/common/menus/config_list.sh" rows | while IFS=$'\t' read -r label path hint _display; do
    [ -n "$label" ] || continue
    _help_collect_row "Edit - $label" "edit:$path" "$hint"
  done
}

_help_collect_row() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3"
}

_help_list_rows() {
  local tmp label action hint display max=0 len
  tmp=$(mktemp)
  # shellcheck disable=SC2061
  trap 'rm -f "$tmp"' RETURN

  _help_collect_rows >"$tmp"

  while IFS=$'\t' read -r label action hint; do
    len=${#label}
    (( len > max )) && max=$len
  done <"$tmp"

  while IFS=$'\t' read -r label action hint; do
    display=$(_fzf_row_display "$max" "$label" "$hint")
    printf '%s\t%s\t%s\t%s\n' "$label" "$action" "$hint" "$display"
  done <"$tmp"
}

case "${1:-}" in
  rows) _help_list_rows ;;
  *)
    printf 'Usage: %s rows\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
