#!/usr/bin/env bash
# Throttled dotfiles update notice (chezmoi login_checks-style).
#
# Sourced from rc.sh on interactive shells. Fetches at most once every 4 days,
# then prints a one-line hint when the repo is behind its upstream branch.
#
# Opt out in ~/.local.sh: export TERMINAL_CONFIG_UPDATE_CHECK=0

# shellcheck source=helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"

terminal_config_update_check() {
  case "${TERMINAL_CONFIG_UPDATE_CHECK:-1}" in
    0|false|False|FALSE|no|NO|off|OFF) return 0 ;;
  esac

  local repo="$DOTFILES_DIR"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-config"
  local stamp="$cache_dir/last-fetch"
  local now last age interval=$((4 * 86400))

  [ -d "$repo/.git" ] || return 0

  mkdir -p "$cache_dir"
  now=$(date +%s)

  if [ -f "$stamp" ]; then
    last=$(cat "$stamp" 2>/dev/null) || last=0
    age=$((now - last))
    [ "$age" -lt "$interval" ] && return 0
  fi

  git -C "$repo" fetch --quiet 2>/dev/null || return 0
  printf '%s\n' "$now" >"$stamp"

  git -C "$repo" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1 || return 0
  [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && return 0

  local behind
  behind=$(git -C "$repo" rev-list --count HEAD..'@{upstream}' 2>/dev/null) || return 0
  [ "${behind:-0}" -eq 0 ] && return 0

  if [ "$behind" -eq 1 ]; then
    printf '\n%sNew terminal-config update available!%s Run %s./update.sh%s to get it.\n\n' \
      "$CYAN" "$RESET" "$CYAN" "$RESET"
  else
    printf '\n%sNew terminal-config updates available (%s)!%s Run %s./update.sh%s to get them.\n\n' \
      "$CYAN" "$behind" "$RESET" "$CYAN" "$RESET"
  fi
}
