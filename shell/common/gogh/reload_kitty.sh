#!/usr/bin/env bash
# Re-sync Kitty after Gogh writes colors.conf. Gogh already signals SIGUSR1 once;
# clear tmux per-pane OSC overrides first so the reload repaints the full pane.
set -u

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$_dir/clear_tmux_pane_colors.sh" --session 2>/dev/null || true

if command -v kitty >/dev/null 2>&1; then
  pkill -USR1 -x kitty 2>/dev/null || killall -USR1 kitty 2>/dev/null || true
fi
