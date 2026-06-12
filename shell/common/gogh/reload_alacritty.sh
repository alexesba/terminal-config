#!/usr/bin/env bash
# Nudge Alacritty to reload after Gogh writes alacritty.toml (whole window, including
# panes outside tmux). Clears tmux per-pane OSC overrides first.
set -u

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$_dir/clear_tmux_pane_colors.sh" --session 2>/dev/null || true

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
[ -f "$cfg" ] || exit 0
touch "$cfg"
