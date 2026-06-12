#!/usr/bin/env bash
# Re-apply the persisted Gogh theme to tmux panes (WezTerm only).
#
# Installed as ~/.tmux/apply-gogh-theme.sh (see update.sh). Hooks must NOT send
# WezTerm OSC inside Kitty/Alacritty — see _wezterm_target and terminal-theming.md.
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

_hook_process_comm() {
  ps -o comm= -p "$1" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_hook_parent_pid() {
  ps -o ppid= -p "$1" 2>/dev/null | awk 'NF { print $1; exit }'
}

_hook_normalize_name() {
  local base="${1##*/}"
  base="${base%.app}"
  printf '%s' "$base" | tr '[:upper:]' '[:lower:]'
}

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

# Outer emulator hosting this tmux client (works in run-shell hooks without TMUX).
# Duplicated from terminal_detect client walk so ~/.tmux/apply-gogh-theme.sh stays standalone.
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
  # Never apply WezTerm OSC when the outer terminal is kitty or alacritty, even if
  # ~/.local.sh / gogh state still say wezterm (common with tmux hooks).
  # Do not infer wezterm from ~/.local.sh alone — that caused wrong tmux pane colors.
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
