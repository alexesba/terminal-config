#!/usr/bin/env bash
# tmux session helpers: tmux-start, tmux-list, tmux-switch, and shared attach logic.
# Sourced from zsh and bash (avoid bash-only process substitution in while loops).

_tmux_require() {
  command -v tmux >/dev/null 2>&1 || {
    echo "tmux not found" >&2
    return 1
  }
}

_tmux_use_color() {
  [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]
}

# helpers.sh (via update_check) defines these; fall back when sourced in tests.
_tmux_c() {
  _tmux_use_color || return 0
  printf '%b' "${1:-}"
}

_tmux_c_reset() { _tmux_c "${RESET:-\033[0m}"; }

_tmux_colored() {
  local code="$1" text="$2"
  if _tmux_use_color; then
    _tmux_c "$code"
    printf '%s' "$text"
    _tmux_c_reset
  else
    printf '%s' "$text"
  fi
}

# Fixed-width cell: color the text, pad with plain spaces after reset.
_tmux_cell() {
  local width=$1 code="$2" text="$3" pad
  pad=$((width - ${#text}))
  (( pad < 0 )) && pad=0
  if [ -n "$code" ]; then
    _tmux_colored "$code" "$text"
  else
    printf '%s' "$text"
  fi
  printf '%*s' "$pad" ''
}

# Prints name|path|attached_clients|windows. Pipe delimiter — tmux -F '\t' is literal.
tmux_sessions_tsv() {
  tmux list-sessions -F '#{session_name}|#{session_path}|#{session_attached}|#{session_windows}' 2>/dev/null
}

_tmux_parse_row() {
  local row="$1"
  _TMUX_ROW_WINDOWS="${row##*|}"
  row="${row%|*}"
  _TMUX_ROW_ATTACHED="${row##*|}"
  row="${row%|*}"
  _TMUX_ROW_NAME="${row%%|*}"
  _TMUX_ROW_PATH="${row#*|}"
}

_tmux_attached_p() {
  [ "${1:-0}" -gt 0 ] 2>/dev/null
}

_tmux_status_label() {
  local client_count="$1" win_count="${2:-1}"
  if _tmux_attached_p "$client_count"; then
    if [ "$win_count" -gt 1 ] 2>/dev/null; then
      printf 'attached (%sw)' "$win_count"
    else
      printf 'attached'
    fi
  elif [ "$win_count" -gt 1 ] 2>/dev/null; then
    printf 'detached (%sw)' "$win_count"
  else
    printf 'detached'
  fi
}

_tmux_status_colored() {
  local client_count="$1" win_count="$2" label
  label="$(_tmux_status_label "$client_count" "$win_count")"
  if _tmux_attached_p "$client_count"; then
    _tmux_colored "${GREEN:-\033[1;32m}" "$label"
  else
    _tmux_colored "${DIM:-\033[2m}" "$label"
  fi
}

_tmux_table_row_colored() {
  local w_sess=$1 w_stat=$2 w_path=$3
  local sess_name=$4 stat_label=$5 sess_path=$6 client_count=$7
  local green="${GREEN:-\033[1;32m}"
  local dim="${DIM:-\033[2m}"

  printf '  '
  if _tmux_attached_p "$client_count"; then
    _tmux_cell "$w_sess" "$green" "$sess_name"
  else
    _tmux_cell "$w_sess" "" "$sess_name"
  fi
  printf '  '
  if _tmux_attached_p "$client_count"; then
    _tmux_cell "$w_stat" "$green" "$stat_label"
  else
    _tmux_cell "$w_stat" "$dim" "$stat_label"
  fi
  printf '  '
  _tmux_cell "$w_path" "$dim" "$sess_path"
  printf '\n'
}

_tmux_short_path() {
  local p="$1" home="${HOME:-}"
  case "$p" in
    "$home"/*) printf '~/%s' "${p#"$home"/}" ;;
    *) printf '%s' "$p" ;;
  esac
}

_tmux_repeat() {
  local char="$1" count="$2" out="" i=0
  while [ "$i" -lt "$count" ]; do
    out="${out}${char}"
    i=$((i + 1))
  done
  printf '%s' "$out"
}

_tmux_format_fzf_lines() {
  local lines="$1" sess_name sess_path client_count win_count stat_out name_out path_out
  [ -n "$lines" ] || return 0
  while IFS='|' read -r sess_name sess_path client_count win_count; do
    [ -n "$sess_name" ] || continue
    sess_path="$(_tmux_short_path "$sess_path")"
    stat_out="$(_tmux_status_colored "$client_count" "$win_count")"
    if _tmux_attached_p "$client_count"; then
      name_out="$(_tmux_colored "${GREEN:-\033[1;32m}" "$sess_name")"
    else
      name_out="$sess_name"
    fi
    path_out="$(_tmux_colored "${DIM:-\033[2m}" "$sess_path")"
    printf '%s\t%s\t%s\t%s\n' "$stat_out" "$name_out" "$path_out" "$sess_name"
  done <<EOF
$lines
EOF
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

function tmux-start {
  local tmux_dirname tmux_app
  _tmux_require || return

  tmux_dirname="${1:-$(pwd)}"

  if test "$tmux_dirname" = "."; then
    tmux_dirname="$(pwd)"
  fi

  tmux_dirname="$(cd "$tmux_dirname" && pwd)" || return

  tmux_app="$(basename "$tmux_dirname")"

  if ! tmux has-session -t "$tmux_app" 2>/dev/null; then
    echo "No Session found.  Creating and configuring."
    tmux new-session -d -s "$tmux_app" -c "$tmux_dirname" || return
  else
    echo "Session found.  Connecting."
  fi

  tmux_attach_session "$tmux_app"
}

_tmux_sessions_table() {
  # sess_path — not "path"; zsh reserves $path for command lookup.
  local lines row sess_name sess_path client_count win_count
  local w_sess=7 w_stat=6 w_path=4
  local rows=() stat_label bold_cyan="${BOLD:-\033[1m}${CYAN:-\033[1;36m}" dim="${DIM:-\033[2m}"

  lines="$(tmux_sessions_tsv)" || return 0
  [ -n "$lines" ] || return 0

  while IFS='|' read -r sess_name sess_path client_count win_count; do
    [ -n "$sess_name" ] || continue
    sess_path="$(_tmux_short_path "$sess_path")"
    stat_label="$(_tmux_status_label "$client_count" "$win_count")"
    [ "${#sess_name}" -gt "$w_sess" ] && w_sess=${#sess_name}
    [ "${#stat_label}" -gt "$w_stat" ] && w_stat=${#stat_label}
    [ "${#sess_path}" -gt "$w_path" ] && w_path=${#sess_path}
    rows+=("${sess_name}|${sess_path}|${client_count}|${win_count}")
  done <<EOF
$lines
EOF

  [ "${#rows[@]}" -eq 0 ] && return 0

  [ "$w_sess" -lt 7 ] && w_sess=7
  [ "$w_stat" -lt 6 ] && w_stat=6
  [ "$w_path" -lt 4 ] && w_path=4

  printf '\n'
  printf '  '
  _tmux_cell "$w_sess" "$bold_cyan" "Session"
  printf '  '
  _tmux_cell "$w_stat" "$bold_cyan" "Status"
  printf '  '
  _tmux_cell "$w_path" "$bold_cyan" "Path"
  printf '\n'
  printf '  '
  _tmux_cell "$w_sess" "$dim" "$(_tmux_repeat '-' "$w_sess")"
  printf '  '
  _tmux_cell "$w_stat" "$dim" "$(_tmux_repeat '-' "$w_stat")"
  printf '  '
  _tmux_cell "$w_path" "$dim" "$(_tmux_repeat '-' "$w_path")"
  printf '\n'

  for row in "${rows[@]}"; do
    _tmux_parse_row "$row"
    sess_name="$_TMUX_ROW_NAME"
    sess_path="$_TMUX_ROW_PATH"
    client_count="$_TMUX_ROW_ATTACHED"
    win_count="$_TMUX_ROW_WINDOWS"
    stat_label="$(_tmux_status_label "$client_count" "$win_count")"
    _tmux_table_row_colored "$w_sess" "$w_stat" "$w_path" \
      "$sess_name" "$stat_label" "$sess_path" "$client_count"
  done
  printf '\n'
}

function tmux-list {
  _tmux_require || return
  if ! tmux_sessions_tsv | grep -q .; then
    _tmux_colored "${YELLOW:-\033[1;33m}" "No tmux sessions."
    return 0
  fi
  _tmux_sessions_table
}

function tmux-switch {
  local selection lines
  _tmux_require || return
  command -v fzf >/dev/null 2>&1 || {
    echo "fzf not found" >&2
    return 1
  }
  lines="$(tmux_sessions_tsv)" || {
    _tmux_colored "${YELLOW:-\033[1;33m}" "No tmux sessions."
    return 1
  }
  [ -n "$lines" ] || {
    _tmux_colored "${YELLOW:-\033[1;33m}" "No tmux sessions."
    return 1
  }
  selection="$(
    _tmux_format_fzf_lines "$lines" | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1,2,3 \
      --accept-nth=4 \
      --header=$'tmux sessions \033[2m(status · Nw = window count)\033[0m' \
      --prompt=$'\033[1;36mtmux\033[0m> ' \
      --height=40% \
      --border=rounded \
      --border-label=$'\033[1;36m tmux \033[0m'
  )" || return
  [ -z "$selection" ] && return
  tmux_attach_session "$selection"
}
