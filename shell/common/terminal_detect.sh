#!/usr/bin/env bash
# Detect the outer terminal emulator hosting this shell (alacritty / kitty / wezterm).
#
# Usage: detect_terminal_emulator   — print name or exit 1
#
# Design notes (detection order, tmux pitfalls): shell/common/terminal-theming.md

_terminal_process_comm() {
  # macOS GUI apps often lack comm=; ucomm= is the fallback.
  local comm
  comm="$(ps -o comm= -p "$1" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -n "$comm" ] && [ "$comm" != "-" ]; then
    printf '%s' "$comm"
    return 0
  fi
  ps -o ucomm= -p "$1" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_terminal_parent_pid() {
  ps -o ppid= -p "$1" 2>/dev/null | awk 'NF { print $1; exit }'
}

_terminal_normalize_name() {
  local base="${1##*/}"
  base="${base%.app}"
  printf '%s' "$base" | tr '[:upper:]' '[:lower:]'
}

# Accept only gogh-supported names; recover from corrupted tmux session values
# (e.g. "alacritty"; export TERMINAL; from a bad eval).
_normalize_detected_terminal() {
  local raw="${1:-}" stripped
  [ -n "$raw" ] || return 1

  case "$raw" in
    alacritty|kitty|wezterm)
      printf '%s\n' "$raw"
      return 0
    ;;
  esac

  stripped="$(printf '%s' "$raw" | tr -d '"' | sed 's/;.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
    | tr '[:upper:]' '[:lower:]')"
  case "$stripped" in
    alacritty|kitty|wezterm)
      printf '%s\n' "$stripped"
      return 0
    ;;
  esac

  case "$raw" in
    *alacritty*) printf 'alacritty\n'; return 0 ;;
    *kitty*)     printf 'kitty\n'; return 0 ;;
    *wezterm*)   printf 'wezterm\n'; return 0 ;;
  esac
  return 1
}

_detect_terminal_from_pid() {
  # Walk parent chain until we find alacritty|kitty|wezterm (skips tmux, zsh, etc.).
  local pid="$1" ppid comm base
  [ -n "$pid" ] || return 1
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    comm="$(_terminal_process_comm "$pid")" || break
    [ -n "$comm" ] || break
    base="$(_terminal_normalize_name "$comm")"
    case "$base" in
      alacritty|kitty|wezterm)
        printf '%s\n' "$base"
        return 0
        ;;
    esac
    ppid="$(_terminal_parent_pid "$pid")" || break
    [ -z "$ppid" ] || [ "$ppid" = "$pid" ] && break
    pid="$ppid"
  done
  return 1
}

_detect_terminal_env() {
  # Fast path outside tmux; env vars often missing inside tmux panes.
  if [ -n "${KITTY_WINDOW_ID:-}" ]; then
    printf 'kitty'
    return 0
  fi
  if [ -n "${ALACRITTY_SOCKET:-}" ] || [ -n "${ALACRITTY_LOG:-}" ]; then
    printf 'alacritty'
    return 0
  fi
  if [ -n "${WEZTERM_EXECUTABLE:-}" ] || [ -n "${WEZTERM_PANE:-}" ]; then
    printf 'wezterm'
    return 0
  fi
  case "${TERM_PROGRAM:-}" in
    WezTerm|wezterm) printf 'wezterm'; return 0 ;;
    kitty)           printf 'kitty'; return 0 ;;
  esac
  case "${TERM:-}" in
    alacritty)  printf 'alacritty'; return 0 ;;
    xterm-kitty) printf 'kitty'; return 0 ;;
  esac
  return 1
}

_detect_terminal_client_walk() {
  # Prefer #{client_pid} for this pane's client, then other attached clients.
  command -v tmux >/dev/null 2>&1 || return 1

  local client_pid detected current_client
  current_client="$(tmux display-message -p '#{client_pid}' 2>/dev/null)"
  if [ -n "$current_client" ]; then
    detected="$(_detect_terminal_from_pid "$current_client" 2>/dev/null || true)"
    if [ -n "$detected" ]; then
      printf '%s\n' "$detected"
      return 0
    fi
  fi

  while IFS= read -r client_pid; do
    [ -n "$client_pid" ] || continue
    [ "$client_pid" = "$current_client" ] && continue
    detected="$(_detect_terminal_from_pid "$client_pid" 2>/dev/null || true)"
    if [ -n "$detected" ]; then
      printf '%s\n' "$detected"
      return 0
    fi
  done < <(tmux list-clients -F '#{client_pid}' 2>/dev/null)
  return 1
}

_detect_terminal_session_env() {
  # Last resort in tmux — session TERMINAL is often stale (wezterm from ~/.local.sh).
  [ -n "${TMUX:-}" ] || return 1
  command -v tmux >/dev/null 2>&1 || return 1

  local session_term normalized
  session_term="$(tmux show-environment -s TERMINAL 2>/dev/null | sed -n 's/^TERMINAL=//p' | head -n1)"
  normalized="$(_normalize_detected_terminal "$session_term" 2>/dev/null || true)"
  [ -n "$normalized" ] || return 1
  printf '%s\n' "$normalized"
}

_detect_terminal_parents() {
  _detect_terminal_from_pid "$$"
}

_detect_terminal_try() {
  local raw="$1" normalized
  [ -n "$raw" ] || return 1
  normalized="$(_normalize_detected_terminal "$raw" 2>/dev/null || true)"
  [ -n "$normalized" ] || return 1
  printf '%s\n' "$normalized"
}

detect_terminal_emulator() {
  # Order documented in shell/common/terminal-theming.md
  local detected

  if [ -n "${TMUX:-}" ]; then
    detected="$(_detect_terminal_try "$(_detect_terminal_client_walk 2>/dev/null || true)" || true)"
    [ -n "$detected" ] && printf '%s\n' "$detected" && return 0
  fi

  detected="$(_detect_terminal_try "$(_detect_terminal_env 2>/dev/null || true)" || true)"
  [ -n "$detected" ] && printf '%s\n' "$detected" && return 0

  detected="$(_detect_terminal_try "$(_detect_terminal_parents 2>/dev/null || true)" || true)"
  [ -n "$detected" ] && printf '%s\n' "$detected" && return 0

  if [ -n "${TMUX:-}" ]; then
    detected="$(_detect_terminal_try "$(_detect_terminal_session_env 2>/dev/null || true)" || true)"
    [ -n "$detected" ] && printf '%s\n' "$detected" && return 0
  fi

  return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_terminal_emulator
  exit $?
fi
