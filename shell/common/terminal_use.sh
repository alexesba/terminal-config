# Session-only TERMINAL override for colorscheme / apply_saved.
# Install default stays in ~/.local.sh (set by install.sh).

# shellcheck source=../../lib/helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"
# shellcheck source=../../lib/fonts.sh disable=SC1091
source "$DOTFILES_DIR/lib/fonts.sh"

_terminal_list_script() {
  printf '%s/shell/common/terminal_list.sh\n' "$DOTFILES_DIR"
}

_terminal_default() {
  custom_export_value "$(local_sh_path)" TERMINAL || true
}

_terminal_config_path() {
  case "$1" in
    alacritty) printf '%s/.config/alacritty/alacritty.toml\n' "$HOME" ;;
    kitty)     printf '%s/.config/kitty/kitty.conf\n' "$HOME" ;;
    wezterm)   printf '%s/.config/wezterm/wezterm.lua\n' "$HOME" ;;
  esac
}

_use_terminal_help() {
  cat <<EOF
Usage: use-terminal [reset|default|alacritty|kitty|wezterm|apply] [apply]

  use-terminal                 Fuzzy-pick an installed terminal (requires fzf)
  use-terminal status          Show current target and install default
  use-terminal kitty           Point colorscheme at Kitty for this shell only
  use-terminal reset           Restore TERMINAL from ~/.local.sh
  use-terminal kitty apply     Switch and re-apply the saved Gogh theme

Install default is unchanged in ~/.local.sh. Run update.sh once if a terminal
config is missing (~/.config/<app>/…).
EOF
}

_use_terminal_activate() {
  local term="$1" apply="$2" default="$3" cfg
  cfg="$(_terminal_config_path "$term")"
  if [ -n "$cfg" ] && [ ! -f "$cfg" ]; then
    printf 'Config not found: %s\n' "$cfg" >&2
    printf 'Run ./update.sh to copy the repo template, or re-run install.sh for that terminal.\n' >&2
    return 1
  fi

  export TERMINAL="$term"
  export TERMINAL_OVERRIDE=1
  bash "$DOTFILES_DIR/shell/common/gogh/persist.sh" --terminal "$term" 2>/dev/null || true
  printf 'TERMINAL=%s for this shell (default: %s). colorscheme will target %s.\n' \
    "$term" "$default" "$term"
  printf 'Run: use-terminal reset\n'

  if [ "$apply" = true ]; then
    bash "$DOTFILES_DIR/shell/common/gogh/apply_saved.sh"
  fi
}

_use_terminal_menu() {
  local default current selection list_script header lines
  list_script="$(_terminal_list_script)"
  default="$(_terminal_default)"
  default="${default:-wezterm}"
  current="${TERMINAL:-$default}"

  command -v fzf >/dev/null 2>&1 || {
    printf 'fzf not found\n' >&2
    return 1
  }

  lines="$(bash "$list_script" rows "$current" "$default")" || true
  if [ -z "$lines" ]; then
    printf 'No supported terminals installed (alacritty, kitty, wezterm).\n' >&2
    return 1
  fi

  header="$(_TERMINAL_COLOR_FORCE=1 bash "$list_script" header "$current" "$default")"
  selection="$(
    bash "$list_script" fzf-pipe "$current" "$default" | FZF_DEFAULT_OPTS='--layout=default --no-preview' fzf \
      --ansi \
      --no-sort \
      --header="$header" \
      --header-lines=1 \
      --delimiter=$'\t' \
      --with-nth=1,2,3 \
      --accept-nth=4 \
      --prompt=$'\033[1;36mterminal\033[0m> ' \
      --height=40% \
      --border=rounded \
      --border-label=$'\033[1;36m terminal \033[0m'
  )" || return
  [ -z "$selection" ] && return

  case "$selection" in
    reset)
      export TERMINAL="$default"
      unset TERMINAL_OVERRIDE
      bash "$DOTFILES_DIR/shell/common/gogh/persist.sh" --terminal "$default" 2>/dev/null || true
      printf 'TERMINAL=%s (from ~/.local.sh)\n' "$default"
      ;;
    *)
      _use_terminal_activate "$selection" false "$default"
      ;;
  esac
}

use-terminal() {
  local default term apply=false list_script
  default="$(_terminal_default)"
  default="${default:-wezterm}"

  case "${1:-}" in
    -h|--help|help)
      _use_terminal_help
      return 0
      ;;
    status)
      printf 'TERMINAL=%s  default=%s\n' "${TERMINAL:-$default}" "$default"
      if [ "${TERMINAL_OVERRIDE:-}" = 1 ] || [ "${TERMINAL:-}" != "$default" ]; then
        printf 'Session override active — run: use-terminal reset\n'
      fi
      return 0
      ;;
    reset|default)
      export TERMINAL="$default"
      unset TERMINAL_OVERRIDE
      bash "$DOTFILES_DIR/shell/common/gogh/persist.sh" --terminal "$default" 2>/dev/null || true
      printf 'TERMINAL=%s (from ~/.local.sh)\n' "$default"
      return 0
      ;;
    apply|--apply)
      bash "$DOTFILES_DIR/shell/common/gogh/apply_saved.sh"
      return $?
      ;;
    alacritty|kitty|wezterm)
      term="$1"
      shift
      ;;
    "")
      _use_terminal_menu
      return $?
      ;;
    *)
      printf 'Unknown terminal: %s\n' "$1" >&2
      _use_terminal_help >&2
      return 1
      ;;
  esac

  if ! is_colorscheme_terminal "$term"; then
    printf 'Not supported by colorscheme: %s\n' "$term" >&2
    return 1
  fi

  case "${1:-}" in
    apply|--apply) apply=true ;;
  esac

  _use_terminal_activate "$term" "$apply" "$default"
}
