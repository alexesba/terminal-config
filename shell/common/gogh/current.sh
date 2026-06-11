#!/usr/bin/env bash
# Detect the active Gogh theme. Prints: DISPLAY_NAME<TAB>theme.sh
#
# Usage: current.sh [gogh_installs_dir]

gogh_dir="${1:-${GOGH_DIR:-$HOME/src/gogh}/installs}"
state="${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"

name=""
file=""

profile_name_from_file() {
  sed -n 's/^export PROFILE_NAME="\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -n1
}

file_from_profile_name() {
  local want="$1" f n
  for f in "$gogh_dir"/*.sh; do
    [ -f "$f" ] || continue
    n=$(profile_name_from_file "$f")
    [ "$n" = "$want" ] && { basename "$f"; return 0; }
  done
  return 1
}

if [ -f "$state" ]; then
  name=$(sed -n 's/^name=//p' "$state" | head -n1)
  file=$(sed -n 's/^file=//p' "$state" | head -n1)
fi

if [ -z "$file" ]; then
  wezterm_colors="${WEZTERM_CONFIG_DIR:-$HOME/.config/wezterm}/colors.lua"
  if [ -f "$wezterm_colors" ]; then
    file=$(sed -n 's/^-- Source theme: //p' "$wezterm_colors" | head -n1)
  fi
fi

if [ -z "$name" ]; then
  kitty_colors="${KITTY_CONFIG_DIRECTORY:-$HOME/.config/kitty}/colors.conf"
  if [ -f "$kitty_colors" ]; then
    name=$(sed -n 's/^# Color theme: //p' "$kitty_colors" | head -n1)
    [ -z "$file" ] && [ -n "$name" ] && file=$(file_from_profile_name "$name" || true)
  fi
fi

if [ -n "$file" ] && [ -z "$name" ] && [ -f "$gogh_dir/$file" ]; then
  name=$(profile_name_from_file "$gogh_dir/$file")
fi

[ -z "$name" ] && [ -n "$file" ] && name="${file%.sh}"

printf '%s\t%s\n' "$name" "$file"
