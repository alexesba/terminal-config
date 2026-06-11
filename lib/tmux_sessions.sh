#!/usr/bin/env bash
# Shared tmux session listing, switching, and attach helpers.

_tmux_require() {
  command -v tmux >/dev/null 2>&1 || {
    echo "tmux not found" >&2
    return 1
  }
}

# Prints session_name|path|attached (0|1). Pipe delimiter — tmux -F '\t' is literal.
tmux_sessions_tsv() {
  tmux list-sessions -F '#{session_name}|#{session_path}|#{session_attached}' 2>/dev/null
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

_tmux_sessions_table() {
  local home="${HOME:-}"
  tmux_sessions_tsv | awk -F'|' -v home="$home" '
    function shortpath(p,    prefix) {
      prefix = home "/"
      if (home != "" && index(p, prefix) == 1) {
        return "~/" substr(p, length(prefix) + 1)
      }
      return p
    }
    function h_border(left, mid, right, w1, w2, w3,    s, i, pad) {
      pad = 2
      s = left
      for (i = 0; i < w1 + pad; i++) s = s "─"
      s = s mid
      for (i = 0; i < w2 + pad; i++) s = s "─"
      s = s mid
      for (i = 0; i < w3 + pad; i++) s = s "─"
      return s right
    }
    {
      status = ($3 == 1) ? "\xe2\x97\x8f" : " "
      path = shortpath($2)
      rows[NR] = status SUBSEP $1 SUBSEP path
      if (length(status) > w_status) w_status = length(status)
      if (length($1) > w_session) w_session = length($1)
      if (length(path) > w_path) w_path = length(path)
    }
    END {
      if (NR == 0) exit
      w_status = (w_status < 6) ? 6 : w_status
      w_session = (w_session < 7) ? 7 : w_session
      w_path = (w_path < 4) ? 4 : w_path

      printf " %s\n", h_border("╭", "┬", "╮", w_status, w_session, w_path)
      printf " │ %-*s │ %-*s │ %-*s │\n", \
        w_status, "Status", w_session, "Session", w_path, "Path"
      printf " %s\n", h_border("├", "┼", "┤", w_status, w_session, w_path)

      for (i = 1; i <= NR; i++) {
        split(rows[i], c, SUBSEP)
        printf " │ %-*s │ %-*s │ %-*s │\n", \
          w_status, c[1], w_session, c[2], w_path, c[3]
      }

      printf " %s\n", h_border("╰", "┴", "╯", w_status, w_session, w_path)
    }
  '
}

function tmux-list {
  _tmux_require || return
  if ! tmux_sessions_tsv | grep -q .; then
    echo "No tmux sessions."
    return 0
  fi
  _tmux_sessions_table
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
    tmux_sessions_tsv | awk -F'|' -v home="${HOME:-}" '
      function shortpath(p) {
        prefix = home "/"
        if (home != "" && index(p, prefix) == 1) {
          return "~/" substr(p, length(prefix) + 1)
        }
        return p
      }
      {
        mark = ($3 == 1) ? "\xe2\x97\x8f" : " "
        path = shortpath($2)
        printf "%s\t%s\t%s\t%s\n", mark, $1, path, $1
      }
    ' | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2,3 \
      --accept-nth=4 \
      --header='tmux sessions (● = attached)' \
      --prompt='tmux> ' \
      --height=40% \
      --border=rounded
  )" || return
  [ -z "$selection" ] && return
  tmux_attach_session "$selection"
}
