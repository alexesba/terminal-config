#!/usr/bin/env bash
# Detect the active Gogh theme for the hosting terminal. Prints: DISPLAY_NAME<TAB>theme.sh
#
# Usage: current.sh [gogh_installs_dir] [terminal]
#        TERMINAL env is used when terminal arg is omitted.

gogh_dir="${1:-${GOGH_DIR:-$HOME/src/gogh}/installs}"
term="${2:-${TERMINAL:-}}"

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_dotfiles="${DOTFILES_DIR:-$(cd "$_dir/../../.." && pwd)}"
# shellcheck source=state.sh disable=SC1091
source "$_dir/state.sh"
# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "$_dotfiles/lib/helpers.sh"

name=""
file=""

# Read PROFILE_NAME from a Gogh theme file without sourcing it.
profile_name_from_file() {
  sed -n 's/^export PROFILE_NAME="\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -n1
}

# Find theme filename in gogh_dir matching PROFILE_NAME $1.
file_from_profile_name() {
  local want="$1" f n
  for f in "$gogh_dir"/*.sh; do
    [ -f "$f" ] || continue
    n=$(profile_name_from_file "$f")
    [ "$n" = "$want" ] && { basename "$f"; return 0; }
  done
  return 1
}

# Read persisted JSON state for the requested terminal.
read_state_for_terminal() {
  local t="$1" line
  line="$(gogh_state_theme_for_terminal "$t")"
  name="${line%%$'\t'*}"
  file="${line#*$'\t'}"
  if [ -n "$name" ] && [ -z "$file" ]; then
    file=$(file_from_profile_name "$name" || true)
  fi
}

# Fallback: read theme markers from emulator config files.
read_config_for_terminal() {
  local t="$1"
  case "$t" in
    wezterm)
      local wezterm_colors
      wezterm_colors="$(wezterm_config_dir)/colors.lua"
      if [ -f "$wezterm_colors" ]; then
        file=$(sed -n 's/^-- Source theme: //p' "$wezterm_colors" | head -n1)
        name=$(sed -n 's/^  scheme_name = "\([^"]*\)",\?$/\1/p' "$wezterm_colors" | head -n1)
      fi
      ;;
    kitty)
      local kitty_colors
      kitty_colors="$(kitty_config_dir)/colors.conf"
      if [ -f "$kitty_colors" ]; then
        name=$(sed -n 's/^# Color theme: //p' "$kitty_colors" | head -n1)
        [ -z "$file" ] && [ -n "$name" ] && file=$(file_from_profile_name "$name" || true)
      fi
      ;;
    alacritty)
      # Alacritty has no Gogh theme marker in config; JSON state is the source of truth.
      :
      ;;
  esac
}

if [ -n "$term" ]; then
  read_state_for_terminal "$term"
  if [ -z "$file" ] && [ -z "$name" ]; then
    read_config_for_terminal "$term"
  fi
else
  # No terminal specified: prefer last_active, then any stored terminal, then config fallbacks.
  gogh_state_migrate_legacy
  term="$(gogh_state_last_active)"
  if [ -n "$term" ]; then
    read_state_for_terminal "$term"
  fi
  if [ -z "$file" ] && [ -z "$name" ]; then
    for t in wezterm kitty alacritty; do
      read_state_for_terminal "$t"
      [ -n "$file" ] || [ -n "$name" ] && break
    done
  fi
  if [ -z "$file" ] && [ -z "$name" ]; then
    for t in wezterm kitty; do
      read_config_for_terminal "$t"
      [ -n "$file" ] || [ -n "$name" ] && break
    done
  fi
fi

if [ -n "$file" ] && [ -z "$name" ] && [ -f "$gogh_dir/$file" ]; then
  name=$(profile_name_from_file "$gogh_dir/$file")
fi

[ -z "$name" ] && [ -n "$file" ] && name="${file%.sh}"

printf '%s\t%s\n' "$name" "$file"
