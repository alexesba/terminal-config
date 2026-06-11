#!/usr/bin/env bash
# Shared tmux session listing, switching, and attach helpers.

_tmux_require() {
  command -v tmux >/dev/null 2>&1 || {
    echo "tmux not found" >&2
    return 1
  }
}

# Prints session_name<TAB>path<TAB>attached (0|1) for each session.
tmux_sessions_tsv() {
  tmux list-sessions -F '#{session_name}\t#{session_path}\t#{session_attached}' 2>/dev/null
}

# Attach outside tmux, switch client when already inside a session.
tmux_attach_session() {
  local session="$1"
  [ -n "$session" ] || return 1
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

function tmux-list {
  local lines
  _tmux_require || return
  lines="$(tmux_sessions_tsv)" || {
    echo "No tmux sessions."
    return 0
  }
  [ -n "$lines" ] || {
    echo "No tmux sessions."
    return 0
  }
  printf '  %-20s %s\n' "SESSION" "PATH"
  printf '%s\n' "$lines" | awk -F'\t' '
    {
      mark = ($3 == 1) ? "● " : "  "
      printf "  %s%-18s %s\n", mark, $1, $2
    }
  '
}

function tmux-switch {
  local selection session
  _tmux_require || return
  command -v fzf >/dev/null 2>&1 || {
    echo "fzf not found" >&2
    return 1
  }
  if ! tmux_sessions_tsv | grep -q .; then
    echo "No tmux sessions."
    return 1
  fi
  selection="$(
    tmux_sessions_tsv | awk -F'\t' '{
      mark = ($3 == 1) ? "● " : "  "
      printf "%s%s\t%s\t%s\n", mark, $1, $2, $1
    }' | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --accept-nth=3 \
      --header='tmux sessions (● = attached)' \
      --prompt='tmux> ' \
      --height=40% \
      --border=rounded
  )" || return
  [ -z "$selection" ] && return
  tmux_attach_session "$selection"
}
