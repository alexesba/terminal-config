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
#   apply_persisted.sh --session    — all panes in the current tmux session
set -u

_normalize_session_terminal() {
  local raw="${1:-}" stripped
  [ -n "$raw" ] || return 1
  case "$raw" in
    alacritty|kitty|wezterm) printf '%s' "$raw"; return 0 ;;
  esac
  stripped="$(printf '%s' "$raw" | tr -d '"' | sed 's/;.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
    | tr '[:upper:]' '[:lower:]')"
  case "$stripped" in
    alacritty|kitty|wezterm) printf '%s' "$stripped"; return 0 ;;
  esac
  case "$raw" in
    *alacritty*) printf 'alacritty'; return 0 ;;
    *kitty*) printf 'kitty'; return 0 ;;
    *wezterm*) printf 'wezterm'; return 0 ;;
  esac
  return 1
}

_tmux_session_terminal() {
  command -v tmux >/dev/null 2>&1 || return 1
  local session term
  session="$(tmux display-message -p '#S' 2>/dev/null)" || return 1
  [ -n "$session" ] || return 1
  term="$(tmux show-environment -t "$session" -s TERMINAL 2>/dev/null | sed -n 's/^TERMINAL=//p' | head -n1)"
  [ -n "$term" ] || return 1
  term="$(_normalize_session_terminal "$term" 2>/dev/null || true)"
  [ -n "$term" ] || return 1
  printf '%s\n' "$term"
}

_persisted_terminal() {
  local term state
  if [ -n "${TERMINAL:-}" ]; then
    term="$(_normalize_session_terminal "$TERMINAL" 2>/dev/null || true)"
    if [ -n "$term" ]; then
      printf '%s\n' "$term"
      return 0
    fi
  fi
  term="$(_tmux_session_terminal 2>/dev/null || true)"
  if [ -n "$term" ]; then
    printf '%s\n' "$term"
    return 0
  fi
  state="${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"
  [ -f "$state" ] || return 1
  term="$(sed -n 's/^terminal=//p' "$state" | head -n1)"
  term="$(_normalize_session_terminal "$term" 2>/dev/null || true)"
  [ -n "$term" ] || return 1
  printf '%s\n' "$term"
}

_wezterm_target() {
  # Respect use-terminal / colorscheme target: do not fall through to ~/.local.sh
  # (often wezterm) and trigger WezTerm OSC inside tmux when targeting alacritty.
  local term
  term="$(_persisted_terminal || true)"
  if [ -n "$term" ]; then
    [ "$term" = wezterm ]
    return
  fi
  local local_sh="${HOME:-}/.local.sh"
  [ -f "$local_sh" ] && grep -qE '^[[:space:]]*export TERMINAL=(wezterm|"wezterm")' "$local_sh"
}

_load_persisted_theme() {
  state="${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"
  [ -f "$state" ] || return 1

  file="$(sed -n 's/^file=//p' "$state" | head -n1)"
  [ -n "$file" ] || return 1

  gogh_installs="${GOGH_DIR:-$HOME/src/gogh}/installs"
  theme="$gogh_installs/$file"
  [ -f "$theme" ] || return 1
  return 0
}

_apply_to_tty() {
  local pane_tty="$1"
  [ -e "$pane_tty" ] || return 0

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
}

_apply_to_stdout() {
  GOGH_NONINTERACTIVE=1 TERMINAL=wezterm bash "$theme" >/dev/null 2>&1 || true
}

_apply_tmux_session() {
  command -v tmux >/dev/null 2>&1 || return 0
  [ -n "${TMUX:-}" ] || return 0
  _wezterm_target || return 0
  _load_persisted_theme || return 0

  local tty
  while IFS= read -r tty; do
    [ -n "$tty" ] && _apply_to_tty "$tty"
  done < <(tmux list-panes -s -F '#{pane_tty}')
}

case "${1:-}" in
  --session)
    _apply_tmux_session
    exit 0
    ;;
esac

pane_tty="${1:-}"

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

_load_persisted_theme || exit 0

if [ -n "$pane_tty" ]; then
  _apply_to_tty "$pane_tty"
else
  _apply_to_stdout
fi
