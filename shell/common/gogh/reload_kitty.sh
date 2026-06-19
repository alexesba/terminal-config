#!/usr/bin/env bash
# Re-sync Kitty after Gogh writes colors.conf. Clears tmux per-pane OSC first
# (see clear_tmux_pane_colors.sh). Pass GOGH_TMUX_SESSION when outside tmux.
set -u

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_dotfiles="${DOTFILES_DIR:-$(cd "$_dir/../../.." && pwd)}"
# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "$_dotfiles/lib/helpers.sh"

bash "$_dir/clear_tmux_pane_colors.sh" --session 2>/dev/null || true

if command -v kitty >/dev/null 2>&1; then
  pkill -USR1 -x kitty 2>/dev/null || killall -USR1 kitty 2>/dev/null || true
fi
conf="$(kitty_config_dir)/kitty.conf"
if [ -f "$conf" ]; then
  touch "$conf"
fi
