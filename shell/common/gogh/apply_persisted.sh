#!/usr/bin/env bash
# Re-apply the persisted Gogh theme to tmux panes (WezTerm only).
# Installed as ~/.tmux/apply-gogh-theme.sh (see update.sh).
#
# Usage:
#   apply_persisted.sh              — apply to stdout (interactive shell)
#   apply_persisted.sh /dev/ttysNN  — apply to a tmux pane tty (tmux hook)
#   apply_persisted.sh --session    — all panes in the current tmux session
set -u

# Sanitize TERMINAL values (same rules as terminal_detect _normalize_detected_terminal).
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

# Process command name for PID $1 (hook-local copy; standalone installed script).
_hook_process_comm() {
  ps -o comm= -p "$1" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Parent PID for $1.
_hook_parent_pid() {
  ps -o ppid= -p "$1" 2>/dev/null | awk 'NF { print $1; exit }'
}

# Lowercase basename without .app (Alacritty.app → alacritty).
_hook_normalize_name() {
  local base="${1##*/}"
  base="${base%.app}"
  printf '%s' "$base" | tr '[:upper:]' '[:lower:]'
}

# Walk parent chain from PID $1 until an emulator is found.
_hook_from_pid() {
  local pid="$1" ppid comm base
  [ -n "$pid" ] || return 1
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    comm="$(_hook_process_comm "$pid")" || break
    [ -n "$comm" ] || break
    base="$(_hook_normalize_name "$comm")"
    case "$base" in
      alacritty|kitty|wezterm)
        printf '%s\n' "$base"
        return 0
        ;;
    esac
    ppid="$(_hook_parent_pid "$pid")" || break
    [ -z "$ppid" ] || [ "$ppid" = "$pid" ] && break
    pid="$ppid"
  done
  return 1
}

# Outer emulator for this tmux client (duplicated from terminal_detect for standalone hook).
_hook_hosting_terminal() {
  command -v tmux >/dev/null 2>&1 || return 1

  local client_pid detected
  client_pid="$(tmux display-message -p '#{client_pid}' 2>/dev/null)"
  if [ -n "$client_pid" ]; then
    detected="$(_hook_from_pid "$client_pid" 2>/dev/null || true)"
    if [ -n "$detected" ]; then
      printf '%s\n' "$detected"
      return 0
    fi
  fi

  while IFS= read -r client_pid; do
    [ -n "$client_pid" ] || continue
    detected="$(_hook_from_pid "$client_pid" 2>/dev/null || true)"
    if [ -n "$detected" ]; then
      printf '%s\n' "$detected"
      return 0
    fi
  done < <(tmux list-clients -F '#{client_pid}' 2>/dev/null)
  return 1
}

# TERMINAL from tmux session environment (normalized).
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

# Which emulator to target: env TERMINAL → session TERMINAL → gogh state last_active.
_persisted_terminal() {
  local term
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
  _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=state.sh disable=SC1091
  source "$_dir/state.sh"
  term="$(gogh_state_last_active 2>/dev/null || true)"
  term="$(_normalize_session_terminal "$term" 2>/dev/null || true)"
  [ -n "$term" ] || return 1
  printf '%s\n' "$term"
}

# Return 0 only when WezTerm OSC should be sent.
# Checks outer host first — never send WezTerm OSC inside kitty/alacritty (wrong pane colors).
_wezterm_target() {
  local term hosting
  hosting="$(_hook_hosting_terminal 2>/dev/null || true)"
  hosting="$(_normalize_session_terminal "$hosting" 2>/dev/null || true)"
  case "$hosting" in
    alacritty|kitty) return 1 ;;
    wezterm) return 0 ;;
  esac

  term="$(_persisted_terminal || true)"
  [ "$term" = wezterm ]
}

# Load WezTerm theme path from per-terminal JSON state into $theme.
_load_persisted_theme() {
  local theme_line
  _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=state.sh disable=SC1091
  source "$_dir/state.sh"

  theme_line="$(gogh_state_theme_for_terminal wezterm)"
  file="${theme_line#*$'\t'}"
  [ -n "$file" ] || return 1

  gogh_installs="${GOGH_DIR:-$HOME/src/gogh}/installs"
  theme="$gogh_installs/$file"
  [ -f "$theme" ] || return 1
  return 0
}

# Send persisted theme OSC to pane TTY $1 (WezTerm only; caller checks _wezterm_target).
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

# Apply persisted theme to stdout (interactive WezTerm, not a tmux pane).
_apply_to_stdout() {
  GOGH_NONINTERACTIVE=1 TERMINAL=wezterm bash "$theme" >/dev/null 2>&1 || true
}

# Apply persisted theme OSC to every pane in the current tmux session.
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
