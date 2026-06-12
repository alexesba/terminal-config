#!/usr/bin/env bash
# Clear tmux 3.6+ per-pane OSC palette overrides so file-based terminals
# (kitty, alacritty) inherit config reloads for the whole pane, not just
# lines drawn after the reload.
#
# WezTerm hooks set OSC 10/11/4 per pane; overrides persist until cleared.
#
# Usage:
#   clear_tmux_pane_colors.sh --session              # current tmux session (requires TMUX)
#   clear_tmux_pane_colors.sh --session <name>       # named session (works outside tmux)
#   GOGH_TMUX_SESSION=<name> clear_tmux_pane_colors.sh --session
set -u

_clear_one() {
  # OSC 104/110/111 reset palette; tmux select-pane -P default clears tmux-side state.
  local pane_id="$1" tty="$2"
  [ -n "$tty" ] && [ -e "$tty" ] && \
    printf '\033]104\007\033]110\007\033]111\007' >"$tty" 2>/dev/null || true
  if [ -n "$pane_id" ]; then
    tmux select-pane -t "$pane_id" -P default 2>/dev/null || true
  fi
}

# Clear OSC overrides on all panes in session $1 (or GOGH_TMUX_SESSION / current $TMUX).
_sync_session() {
  local session="${1:-}" pane_id tty
  command -v tmux >/dev/null 2>&1 || return 0

  if [ -z "$session" ] && [ -n "${GOGH_TMUX_SESSION:-}" ]; then
    session="$GOGH_TMUX_SESSION"
  fi

  if [ -n "$session" ]; then
    while IFS= read -r pane_id; do
      [ -z "$pane_id" ] && continue
      tty="$(tmux display-message -p -t "$pane_id" '#{pane_tty}' 2>/dev/null || true)"
      _clear_one "$pane_id" "$tty"
    done < <(tmux list-panes -t "$session" -s -F '#{pane_id}' 2>/dev/null)
    return 0
  fi

  [ -n "${TMUX:-}" ] || return 0

  while IFS= read -r pane_id; do
    [ -z "$pane_id" ] && continue
    tty="$(tmux display-message -p -t "$pane_id" '#{pane_tty}' 2>/dev/null || true)"
    _clear_one "$pane_id" "$tty"
  done < <(tmux list-panes -s -F '#{pane_id}' 2>/dev/null)
}

case "${1:-}" in
  --session)
    shift
    _sync_session "${1:-}"
    ;;
  *)
    printf 'Usage: %s --session [session-name]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
