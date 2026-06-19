#!/usr/bin/env bash
# Nudge Alacritty to reload after Gogh writes alacritty.toml. Clears tmux per-pane
# OSC first. Pass GOGH_TMUX_SESSION when outside tmux (tmux-start does this).
set -u

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_dotfiles="${DOTFILES_DIR:-$(cd "$_dir/../../.." && pwd)}"
# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "$_dotfiles/lib/helpers.sh"

bash "$_dir/clear_tmux_pane_colors.sh" --session 2>/dev/null || true

cfg="$(terminal_emulator_config_path alacritty 2>/dev/null || true)"
[ -n "$cfg" ] && [ -f "$cfg" ] || exit 0
touch "$cfg"
