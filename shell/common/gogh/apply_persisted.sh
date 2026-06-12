#!/usr/bin/env bash
# Re-apply the persisted Gogh theme to tmux panes (WezTerm only).
#
# WezTerm themes via OSC are per-pane and session-only; new tmux splits need OSC
# sent to #{pane_tty}. Kitty and Alacritty write config files instead — new tmux
# panes inherit colours from the outer terminal, so this script is a no-op when
# TERMINAL is not wezterm (see tmux.conf.example hooks).
#
# Usage:
#   apply_persisted.sh              — apply to stdout (interactive shell)
#   apply_persisted.sh /dev/ttysNN  — apply to a tmux pane tty (tmux hook)
set -u

pane_tty="${1:-}"

_wezterm_target() {
  [ "${TERMINAL:-}" = wezterm ] && return 0
  local local_sh="${HOME:-}/.local.sh"
  [ -f "$local_sh" ] && grep -qE '^[[:space:]]*export TERMINAL=(wezterm|"wezterm")' "$local_sh"
}

if [ -n "$pane_tty" ]; then
  [ -e "$pane_tty" ] || exit 0
  _wezterm_target || exit 0
else
  [ -t 1 ] || [ -n "${GOGH_APPLY_PERSISTED_FORCE:-}" ] || exit 0
  if [ "${TERM:-dumb}" = dumb ] && [ -z "${GOGH_APPLY_PERSISTED_FORCE:-}" ]; then
    exit 0
  fi
  _wezterm_target || exit 0
fi

state="${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"
[ -f "$state" ] || exit 0

file="$(sed -n 's/^file=//p' "$state" | head -n1)"
[ -n "$file" ] || exit 0

gogh_installs="${GOGH_DIR:-$HOME/src/gogh}/installs"
theme="$gogh_installs/$file"
[ -f "$theme" ] || exit 0

if [ -n "$pane_tty" ]; then
  gogh_root="${GOGH_DIR:-$HOME/src/gogh}"
  apply_script="$gogh_root/apply-colors.sh"
  if [ -f "$apply_script" ] && grep -q '^export BACKGROUND_COLOR=' "$theme"; then
    # Gogh install scripts discard stdout when GOGH_NONINTERACTIVE is set
    # (apply_theme 1>/dev/null). Load exports and call apply-colors.sh so OSC
    # sequences reach the pane tty; tmux 3.6+ applies OSC 10/11/4 per pane.
    while IFS= read -r line; do
      case "$line" in
        export\ *) eval "$line" ;;
      esac
    done <"$theme"
    TERMINAL=wezterm GOGH_NONINTERACTIVE=1 bash "$apply_script" >"$pane_tty" 2>/dev/null || true
  else
    TERMINAL=wezterm bash "$theme" >"$pane_tty" 2>/dev/null || true
  fi
else
  GOGH_NONINTERACTIVE=1 TERMINAL=wezterm bash "$theme" >/dev/null 2>&1 || true
fi
