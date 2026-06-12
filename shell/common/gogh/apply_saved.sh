#!/usr/bin/env bash
# Re-apply the persisted Gogh theme for the active TERMINAL emulator.
#
# Usage: apply_saved.sh
# Respects TERMINAL in the environment, then ~/.local.sh.
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"
# shellcheck source=../../../lib/fonts.sh disable=SC1091
source "$DOTFILES_DIR/lib/fonts.sh"

term="${TERMINAL:-}"
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

GOGH_NONINTERACTIVE=1 TERMINAL="$term" bash "$theme" >/dev/null 2>&1 || true
