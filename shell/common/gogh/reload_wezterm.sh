#!/usr/bin/env bash
# Nudge WezTerm to reload colors.lua after Gogh writes it. wezterm.lua registers
# the file on the watch list and applies it as config.color_scheme = 'Gogh Active'.
set -u

cfg="${WEZTERM_CONFIG_DIR:-$HOME/.config/wezterm}"
colors="$cfg/colors.lua"
[ -f "$colors" ] || exit 0

# persist.sh already rewrote the file; touch again so reload watchers that
# coalesce events still see a change after colorscheme finishes.
touch "$colors"
sleep 0.05
touch "$colors"
