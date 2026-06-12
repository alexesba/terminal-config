#!/usr/bin/env bash
# Clear tmux 3.6+ per-pane OSC palette overrides so file-based terminals
# (kitty, alacritty) inherit config reloads for the whole pane, not just
# lines drawn after the reload.
set -u

_clear_one() {
  local pane_id="$1" tty="$2"
  [ -n "$tty" ] && [ -e "$tty" ] && \
    printf '\033]104\007\033]110\007\033]111\007' >"$tty" 2>/dev/null || true
  if [ -n "${TMUX:-}" ] && [ -n "$pane_id" ]; then
    tmux select-pane -t "$pane_id" -P default 2>/dev/null || true
  fi
}

_sync_session() {
  [ -n "${TMUX:-}" ] || return 0
  command -v tmux >/dev/null 2>&1 || return 0

  local pane_id tty
  while IFS= read -r pane_id; do
    [ -z "$pane_id" ] && continue
    tty="$(tmux display-message -p -t "$pane_id" '#{pane_tty}' 2>/dev/null || true)"
    _clear_one "$pane_id" "$tty"
  done < <(tmux list-panes -s -F '#{pane_id}' 2>/dev/null)
}

case "${1:-}" in
  --session|'')
    _sync_session
    ;;
  *)
    printf 'Usage: %s [--session]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
