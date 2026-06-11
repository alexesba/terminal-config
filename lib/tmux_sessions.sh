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
    "$home"/*) printf '%s/%s' '~' "${p#"$home"/}" ;;
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

_tmux_session_widths() {
  local lines="$1" sess_name sess_path client_count win_count stat_label
  _TMUX_W_SESS=7
  _TMUX_W_STAT=6
  _TMUX_W_PATH=4
  [ -n "$lines" ] || return 0
  while IFS='|' read -r sess_name sess_path client_count win_count; do
    [ -n "$sess_name" ] || continue
    sess_path="$(_tmux_short_path "$sess_path")"
    stat_label="$(_tmux_status_label "$client_count" "$win_count")"
    [ "${#sess_name}" -gt "$_TMUX_W_SESS" ] && _TMUX_W_SESS=${#sess_name}
    [ "${#stat_label}" -gt "$_TMUX_W_STAT" ] && _TMUX_W_STAT=${#stat_label}
    [ "${#sess_path}" -gt "$_TMUX_W_PATH" ] && _TMUX_W_PATH=${#sess_path}
  done <<EOF
$lines
EOF
  [ "$_TMUX_W_SESS" -lt 7 ] && _TMUX_W_SESS=7
  [ "$_TMUX_W_STAT" -lt 6 ] && _TMUX_W_STAT=6
  [ "$_TMUX_W_PATH" -lt 4 ] && _TMUX_W_PATH=4
}

_tmux_fzf_field() {
  local width=$1 code="$2" text="$3" padded
  padded="$(printf '%-*s' "$width" "$text")"
  if [ -n "$code" ]; then
    _tmux_colored "$code" "$padded"
  else
    printf '%s' "$padded"
  fi
}

# First fzf input row: column titles (paired with --header-lines=1, not selectable).
_tmux_fzf_title_line() {
  local lines="$1"
  local bold_cyan="${BOLD:-\033[1m}${CYAN:-\033[1;36m}"
  _tmux_session_widths "$lines"
  _tmux_fzf_field "$_TMUX_W_SESS" "$bold_cyan" "Session"
  printf '\t'
  _tmux_fzf_field "$_TMUX_W_STAT" "$bold_cyan" "Status"
  printf '\t'
  _tmux_fzf_field "$_TMUX_W_PATH" "$bold_cyan" "Path"
  printf '\t\n'
}

_tmux_format_fzf_lines() {
  local lines="$1" sess_name sess_path client_count win_count
  local stat_label green="${GREEN:-\033[1;32m}" dim="${DIM:-\033[2m}"
  local col1 col2 col3
  [ -n "$lines" ] || return 0
  _tmux_session_widths "$lines"
  while IFS='|' read -r sess_name sess_path client_count win_count; do
    [ -n "$sess_name" ] || continue
    sess_path="$(_tmux_short_path "$sess_path")"
    stat_label="$(_tmux_status_label "$client_count" "$win_count")"
    if _tmux_attached_p "$client_count"; then
      col1="$(_tmux_fzf_field "$_TMUX_W_SESS" "$green" "$sess_name")"
      col2="$(_tmux_fzf_field "$_TMUX_W_STAT" "$green" "$stat_label")"
    else
      col1="$(_tmux_fzf_field "$_TMUX_W_SESS" "" "$sess_name")"
      col2="$(_tmux_fzf_field "$_TMUX_W_STAT" "$dim" "$stat_label")"
    fi
    col3="$(_tmux_colored "$dim" "$sess_path")"
    printf '%s\t%s\t%s\t%s\n' "$col1" "$col2" "$col3" "$sess_name"
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
  local rows=() stat_label bold_cyan="${BOLD:-\033[1m}${CYAN:-\033[1;36m}" dim="${DIM:-\033[2m}"

  lines="$(tmux_sessions_tsv)" || return 0
  [ -n "$lines" ] || return 0

  while IFS='|' read -r sess_name sess_path client_count win_count; do
    [ -n "$sess_name" ] || continue
    rows+=("${sess_name}|${sess_path}|${client_count}|${win_count}")
  done <<EOF
$lines
EOF

  [ "${#rows[@]}" -eq 0 ] && return 0

  _tmux_session_widths "$lines"

  printf '\n'
  printf '  '
  _tmux_cell "$_TMUX_W_SESS" "$bold_cyan" "Session"
  printf '  '
  _tmux_cell "$_TMUX_W_STAT" "$bold_cyan" "Status"
  printf '  '
  _tmux_cell "$_TMUX_W_PATH" "$bold_cyan" "Path"
  printf '\n'
  printf '  '
  _tmux_cell "$_TMUX_W_SESS" "$dim" "$(_tmux_repeat '-' "$_TMUX_W_SESS")"
  printf '  '
  _tmux_cell "$_TMUX_W_STAT" "$dim" "$(_tmux_repeat '-' "$_TMUX_W_STAT")"
  printf '  '
  _tmux_cell "$_TMUX_W_PATH" "$dim" "$(_tmux_repeat '-' "$_TMUX_W_PATH")"
  printf '\n'

  for row in "${rows[@]}"; do
    _tmux_parse_row "$row"
    sess_name="$_TMUX_ROW_NAME"
    sess_path="$(_tmux_short_path "$_TMUX_ROW_PATH")"
    client_count="$_TMUX_ROW_ATTACHED"
    win_count="$_TMUX_ROW_WINDOWS"
    stat_label="$(_tmux_status_label "$client_count" "$win_count")"
    _tmux_table_row_colored "$_TMUX_W_SESS" "$_TMUX_W_STAT" "$_TMUX_W_PATH" \
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
  lines="$(tmux_sessions_tsv)" || {
    _tmux_colored "${YELLOW:-\033[1;33m}" "No tmux sessions."
    return 1
  }
  [ -n "$lines" ] || {
    _tmux_colored "${YELLOW:-\033[1;33m}" "No tmux sessions."
    return 1
  }
  command -v fzf >/dev/null 2>&1 || {
    echo "fzf not found" >&2
    return 1
  }
  selection="$(
    {
      _tmux_fzf_title_line "$lines"
      _tmux_format_fzf_lines "$lines"
    } | FZF_DEFAULT_OPTS='--layout=default --no-preview' fzf \
      --ansi \
      --layout=default \
      --no-sort \
      --header-lines=1 \
      --delimiter=$'\t' \
      --with-nth=1,2,3 \
      --accept-nth=4 \
      --prompt=$'\033[1;36mtmux\033[0m> ' \
      --height=40% \
      --border=rounded \
      --border-label=$'\033[1;36m tmux \033[0m'
  )" || return
  [ -z "$selection" ] && return
  tmux_attach_session "$selection"
}
