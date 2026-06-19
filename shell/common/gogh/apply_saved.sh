#!/usr/bin/env bash
# Re-apply the persisted Gogh theme for the active TERMINAL emulator.
#
# Usage: apply_saved.sh
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi
# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"
# shellcheck source=../../../lib/fonts.sh disable=SC1091
source "$DOTFILES_DIR/lib/fonts.sh"
# shellcheck source=deps.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/gogh/deps.sh"
# shellcheck source=paths.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/gogh/paths.sh"

# Resolve target emulator: TERMINAL env → gogh_resolve_terminal (unless override) → ~/.local.sh.
term="${TERMINAL:-}"
if [ "${TERMINAL_OVERRIDE:-}" != 1 ]; then
  term="$(gogh_resolve_terminal)"
fi
if [ -z "$term" ]; then
  term="$(custom_export_value "$(local_sh_path)" TERMINAL || true)"
fi
[ -n "$term" ] || exit 0
is_colorscheme_terminal "$term" || exit 0

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=state.sh disable=SC1091
source "$_dir/state.sh"

theme_line="$(gogh_state_theme_for_terminal "$term")"
file="${theme_line#*$'\t'}"
[ -n "$file" ] || exit 0

gogh_installs="$(gogh_installs_dir)"
theme="$gogh_installs/$file"
[ -f "$theme" ] || exit 0

gogh_root="$(gogh_repo_root)"
persist_script="$DOTFILES_DIR/shell/common/gogh/persist.sh"

if [ "$term" != wezterm ]; then
  if ! GOGH_NONINTERACTIVE=1 gogh_apply_theme_script "$gogh_root" "$theme" "$term" >/dev/null 2>&1; then
    if [ "$term" = alacritty ] && ! gogh_python_deps_ok; then
      gogh_python_deps_hint
    else
      printf 'Failed to apply saved theme for %s.\n' "$term" >&2
    fi
    exit 1
  fi
fi

[ -f "$persist_script" ] && bash "$persist_script" "$theme" "$term"

if [ "$term" = alacritty ]; then
  bash "$DOTFILES_DIR/shell/common/gogh/reload_alacritty.sh" 2>/dev/null || true
elif [ "$term" = kitty ]; then
  bash "$DOTFILES_DIR/shell/common/gogh/reload_kitty.sh" 2>/dev/null || true
fi
