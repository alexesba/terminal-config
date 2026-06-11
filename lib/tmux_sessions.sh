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
  local line name path attached w_session=7 w_path=4
  local -a rows=()

  while IFS='|' read -r name path attached; do
    [ -n "$name" ] || continue
    path="$(_tmux_short_path "$path")"
    [ "${#name}" -gt "$w_session" ] && w_session=${#name}
    [ "${#path}" -gt "$w_path" ] && w_path=${#path}
    rows+=("${name}|${path}|${attached}")
  done < <(tmux_sessions_tsv)

  [ "${#rows[@]}" -eq 0 ] && return 0

  printf '\n'
  printf '  %-2s %-*s  %s\n' '' "$w_session" "Session" "Path"
  printf '  %-2s %-*s  %s\n' '' "$w_session" "$(_tmux_repeat '-' "$w_session")" "$(_tmux_repeat '-' "$w_path")"

  for line in "${rows[@]}"; do
    IFS='|' read -r name path attached <<< "$line"
    if [ "$attached" = 1 ]; then
      printf '  %-2s %-*s  %s\n' '>' "$w_session" "$name" "$path"
    else
      printf '  %-2s %-*s  %s\n' '' "$w_session" "$name" "$path"
    fi
  done
  printf '\n'
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
  local selection
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
    while IFS='|' read -r name path attached; do
      [ -n "$name" ] || continue
      path="$(_tmux_short_path "$path")"
      if [ "$attached" = 1 ]; then
        printf '>\t%s\t%s\t%s\n' "$name" "$path" "$name"
      else
        printf ' \t%s\t%s\t%s\n' "$name" "$path" "$name"
      fi
    done < <(tmux_sessions_tsv) | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2,3 \
      --accept-nth=4 \
      --header='tmux sessions (> = attached)' \
      --prompt='tmux> ' \
      --height=40% \
      --border=rounded
  )" || return
  [ -z "$selection" ] && return
  tmux_attach_session "$selection"
}
