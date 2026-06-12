#!/usr/bin/env bash
# Nudge Alacritty to reload after Gogh writes alacritty.toml. Clears tmux per-pane
# OSC first. Pass GOGH_TMUX_SESSION when outside tmux (tmux-start does this).
set -u

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$_dir/clear_tmux_pane_colors.sh" --session 2>/dev/null || true

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
[ -f "$cfg" ] || exit 0
touch "$cfg"
