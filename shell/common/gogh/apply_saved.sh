#!/usr/bin/env bash
# Re-apply the persisted Gogh theme for the active TERMINAL emulator.
#
# Usage: apply_saved.sh
# Respects TERMINAL in the environment, then ~/.local.sh.
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
# shellcheck source=../terminal_detect.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/terminal_detect.sh"

term="${TERMINAL:-}"
if [ "${TERMINAL_OVERRIDE:-}" != 1 ]; then
  detected="$(detect_terminal_emulator 2>/dev/null || true)"
  if [ -n "$detected" ] && is_colorscheme_terminal "$detected"; then
    term="$detected"
  fi
fi
if [ -z "$term" ]; then
  term="$(custom_export_value "$(local_sh_path)" TERMINAL || true)"
fi
[ -n "$term" ] || exit 0
is_colorscheme_terminal "$term" || exit 0

state="${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"
[ -f "$state" ] || exit 0

file="$(sed -n 's/^file=//p' "$state" | head -n1)"
[ -n "$file" ] || exit 0

gogh_installs="${GOGH_DIR:-$HOME/src/gogh}/installs"
theme="$gogh_installs/$file"
[ -f "$theme" ] || exit 0

persist_script="$DOTFILES_DIR/shell/common/gogh/persist.sh"

if ! GOGH_NONINTERACTIVE=1 TERMINAL="$term" bash "$theme" >/dev/null 2>&1; then
  if [ "$term" = alacritty ] && ! gogh_python_deps_ok; then
    gogh_python_deps_hint
  else
    printf 'Failed to apply saved theme for %s.\n' "$term" >&2
  fi
  exit 1
fi

[ -f "$persist_script" ] && bash "$persist_script" "$theme" "$term"

if [ "$term" = alacritty ]; then
  bash "$DOTFILES_DIR/shell/common/gogh/reload_alacritty.sh" 2>/dev/null || true
elif [ "$term" = kitty ]; then
  bash "$DOTFILES_DIR/shell/common/gogh/reload_kitty.sh" 2>/dev/null || true
fi
