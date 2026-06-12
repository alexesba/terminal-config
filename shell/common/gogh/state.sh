#!/usr/bin/env bash
# Per-terminal Gogh theme state (pure bash, no Python).
#
#   ~/.local/state/gogh/alacritty   → name= / file=
#   ~/.local/state/gogh/kitty       → name= / file=
#   ~/.local/state/gogh/wezterm     → name= / file=
#   ~/.local/state/gogh/last_active → alacritty | kitty | wezterm
#
# Legacy ~/.local/state/gogh/current (flat or JSON) is migrated on first use.
# Sourced by persist.sh, current.sh, apply_saved.sh.
set -u

GOGH_STATE_TERMINALS=(alacritty kitty wezterm)

gogh_state_dir() {
  if [ -n "${GOGH_STATE_DIR:-}" ]; then
    printf '%s\n' "$GOGH_STATE_DIR"
    return 0
  fi
  if [ -n "${GOGH_STATE_FILE:-}" ]; then
    dirname "$GOGH_STATE_FILE"
    return 0
  fi
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/gogh"
}

gogh_state_legacy_current() {
  if [ -n "${GOGH_STATE_FILE:-}" ]; then
    printf '%s\n' "$GOGH_STATE_FILE"
    return 0
  fi
  printf '%s/current' "$(gogh_state_dir)"
}

gogh_state_terminal_file() {
  printf '%s/%s' "$(gogh_state_dir)" "$1"
}

gogh_state_last_active_file() {
  printf '%s/last_active' "$(gogh_state_dir)"
}

_gogh_state_valid_terminal() {
  case "${1:-}" in
    alacritty|kitty|wezterm) return 0 ;;
    *) return 1 ;;
  esac
}

# Read name= or file= from a terminal state file.
_gogh_state_read_field() {
  local file="$1" field="$2"
  [ -f "$file" ] || return 1
  sed -n "s/^${field}=//p" "$file" | head -n1
}

# Write name= / file= to a terminal state file.
_gogh_state_write_terminal_file() {
  local term="$1" name="$2" file="$3" path
  path="$(gogh_state_terminal_file "$term")"
  mkdir -p "$(gogh_state_dir)"
  {
    [ -n "$name" ] && printf 'name=%s\n' "$name"
    [ -n "$file" ] && printf 'file=%s\n' "$file"
  } >"$path"
}

# Seed empty terminal slots from WezTerm / Kitty config markers.
_gogh_state_seed_from_configs() {
  local term path name file

  path="$(gogh_state_terminal_file wezterm)"
  if [ ! -f "$path" ]; then
    local wezterm_colors="${WEZTERM_CONFIG_DIR:-$HOME/.config/wezterm}/colors.lua"
    if [ -f "$wezterm_colors" ]; then
      file=$(sed -n 's/^-- Source theme: //p' "$wezterm_colors" | head -n1)
      [ -n "$file" ] && _gogh_state_write_terminal_file wezterm "" "$file"
    fi
  fi

  path="$(gogh_state_terminal_file kitty)"
  if [ ! -f "$path" ]; then
    local kitty_colors="${KITTY_CONFIG_DIRECTORY:-$HOME/.config/kitty}/colors.conf"
    if [ -f "$kitty_colors" ]; then
      name=$(sed -n 's/^# Color theme: //p' "$kitty_colors" | head -n1)
      [ -n "$name" ] && _gogh_state_write_terminal_file kitty "$name" ""
    fi
  fi
}

# Migrate legacy flat current (name=/file=/terminal=) into per-terminal files.
_gogh_state_migrate_flat_current() {
  local current="$1" name file term
  [ -f "$current" ] || return 0

  name=$(sed -n 's/^name=//p' "$current" | head -n1)
  file=$(sed -n 's/^file=//p' "$current" | head -n1)
  term=$(sed -n 's/^terminal=//p' "$current" | head -n1)

  mkdir -p "$(gogh_state_dir)"

  if _gogh_state_valid_terminal "$term" && { [ -n "$name" ] || [ -n "$file" ]; }; then
    _gogh_state_write_terminal_file "$term" "$name" "$file"
    printf '%s\n' "$term" >"$(gogh_state_last_active_file)"
  elif [ -n "$name" ] || [ -n "$file" ]; then
    _gogh_state_write_terminal_file wezterm "$name" "$file"
    printf 'wezterm\n' >"$(gogh_state_last_active_file)"
  fi

  _gogh_state_seed_from_configs
  mv "$current" "${current}.migrated"
}

# Migrate JSON current (branch-era format) into per-terminal files.
_gogh_state_migrate_json_current() {
  local current="$1" term block name file
  [ -f "$current" ] || return 0

  mkdir -p "$(gogh_state_dir)"

  for term in "${GOGH_STATE_TERMINALS[@]}"; do
    block=$(sed -n "/\"${term}\"[[:space:]]*:/,/^  }/p" "$current")
    [ -n "$block" ] || continue
    name=$(printf '%s\n' "$block" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    file=$(printf '%s\n' "$block" | sed -n 's/.*"file"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "$name" ] || [ -n "$file" ]; then
      _gogh_state_write_terminal_file "$term" "$name" "$file"
    fi
  done

  term=$(sed -n 's/.*"last_active"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$current" | head -n1)
  if _gogh_state_valid_terminal "$term"; then
    printf '%s\n' "$term" >"$(gogh_state_last_active_file)"
  fi

  _gogh_state_seed_from_configs
  mv "$current" "${current}.migrated"
}

# Migrate legacy ~/.local/state/gogh/current if present.
gogh_state_migrate_legacy() {
  local current first
  current="$(gogh_state_legacy_current)"
  [ -f "$current" ] || return 0

  first=$(sed -n '1p' "$current" | sed 's/^[[:space:]]*//')
  case "$first" in
    \{*) _gogh_state_migrate_json_current "$current" ;;
    *) _gogh_state_migrate_flat_current "$current" ;;
  esac
}

# Print name<TAB>file for terminal $1 (may be empty).
gogh_state_theme_for_terminal() {
  local term="${1:-}" path name file
  [ -n "$term" ] || return 1
  _gogh_state_valid_terminal "$term" || return 1

  gogh_state_migrate_legacy

  path="$(gogh_state_terminal_file "$term")"
  name="$(_gogh_state_read_field "$path" name 2>/dev/null || true)"
  file="$(_gogh_state_read_field "$path" file 2>/dev/null || true)"
  printf '%s\t%s' "${name:-}" "${file:-}"
}

# Print last_active terminal id (alacritty|kitty|wezterm) or empty.
gogh_state_last_active() {
  local path active
  gogh_state_migrate_legacy
  path="$(gogh_state_last_active_file)"
  [ -f "$path" ] || return 0
  active=$(sed -n '1p' "$path" | tr -d '[:space:]')
  _gogh_state_valid_terminal "$active" && printf '%s' "$active"
}

# Persist theme for terminal $1.
gogh_state_write_theme() {
  local term="${1:-}" name="${2:-}" file="${3:-}"
  [ -n "$term" ] || return 1
  _gogh_state_valid_terminal "$term" || return 1

  gogh_state_migrate_legacy
  _gogh_state_write_terminal_file "$term" "$name" "$file"
  mkdir -p "$(gogh_state_dir)"
  printf '%s\n' "$term" >"$(gogh_state_last_active_file)"
}

# Record which emulator was synced (no theme change).
gogh_state_write_last_active() {
  local term="${1:-}"
  [ -n "$term" ] || return 0
  _gogh_state_valid_terminal "$term" || return 0

  gogh_state_migrate_legacy
  mkdir -p "$(gogh_state_dir)"
  printf '%s\n' "$term" >"$(gogh_state_last_active_file)"
}
