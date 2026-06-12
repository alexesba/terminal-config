# Session-only TERMINAL override for colorscheme / apply_saved.
# Install default stays in ~/.local.sh (set by install.sh).

# shellcheck source=../../lib/helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"
# shellcheck source=../../lib/fonts.sh disable=SC1091
source "$DOTFILES_DIR/lib/fonts.sh"
# shellcheck source=terminal_detect.sh disable=SC1091
source "$DOTFILES_DIR/shell/common/terminal_detect.sh"

# Path to terminal_list.sh for the fzf picker.
_terminal_list_script() {
  printf '%s/shell/common/terminal_list.sh\n' "$DOTFILES_DIR"
}

# TERMINAL from ~/.local.sh (install default).
_terminal_default() {
  custom_export_value "$(local_sh_path)" TERMINAL || true
}

# Config file path for a supported emulator id.
_terminal_config_path() {
  case "$1" in
    alacritty) printf '%s/.config/alacritty/alacritty.toml\n' "$HOME" ;;
    kitty)     printf '%s/.config/kitty/kitty.conf\n' "$HOME" ;;
    wezterm)   printf '%s/.config/wezterm/wezterm.lua\n' "$HOME" ;;
  esac
}

# Print use-terminal usage.
_use_terminal_help() {
  cat <<EOF
Usage: use-terminal [reset|detect|sync|default|alacritty|kitty|wezterm|apply] [apply]

  use-terminal                 Fuzzy-pick an installed terminal (requires fzf)
  use-terminal status          Show current target and install default
  use-terminal detect          Detect hosting emulator and set TERMINAL
  use-terminal detect --print  Print detected name only (no change)
  use-terminal detect --export Print: export TERMINAL=<name>  (for eval)
  use-terminal sync            Same as use-terminal detect
  use-terminal kitty           Point colorscheme at Kitty for this shell only
  use-terminal reset           Restore TERMINAL from ~/.local.sh
  use-terminal kitty apply     Switch and re-apply the saved Gogh theme

When TERMINAL_AUTO_DETECT is not 0 (default), interactive shells, colorscheme,
and tmux-start auto-match TERMINAL to the emulator hosting the window. Inside
tmux, new panes inherit the session TERMINAL (see update-environment in
tmux.conf.example) — no use-terminal per pane needed.
EOF
}

# Set TERMINAL + TERMINAL_OVERRIDE for this shell; optionally re-apply saved theme.
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

# fzf menu: pick alacritty|kitty|wezterm or reset to install default.
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
  local fzf_input
  fzf_input="$(bash "$list_script" fzf-pipe "$current" "$default")" || return 1
  [ -n "$fzf_input" ] || return 1
  selection="$(
    printf '%s\n' "$fzf_input" | FZF_DEFAULT_OPTS='--layout=default --no-preview' fzf \
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

# Match TERMINAL to the hosting emulator; update tmux session env when inside tmux.
# Respects TERMINAL_OVERRIDE and TERMINAL_AUTO_DETECT=0 unless $1=1 (use-terminal detect|sync).
sync_terminal_to_host() {
  local force="${1:-0}"
  if [ "$force" != 1 ] && [ "${TERMINAL_AUTO_DETECT:-1}" = 0 ]; then
    return 0
  fi
  [ "${TERMINAL_OVERRIDE:-}" != 1 ] || return 0

  local detected default current cfg
  detected="$(detect_terminal_emulator 2>/dev/null || true)"
  [ -n "$detected" ] || return 0
  is_colorscheme_terminal "$detected" || return 0

  cfg="$(_terminal_config_path "$detected")"
  if [ -n "$cfg" ] && [ ! -f "$cfg" ] && [ "${TERMINAL_AUTO_DETECT_VERBOSE:-}" = 1 ]; then
    printf 'note: %s config missing (%s); run ./update.sh if colorscheme fails\n' \
      "$detected" "$cfg" >&2
  fi

  default="$(_terminal_default)"
  default="${default:-wezterm}"
  current="${TERMINAL:-$default}"

  if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
    local session session_term="" session_normalized=""
    session="$(tmux display-message -p '#S' 2>/dev/null || true)"
    if [ -n "$session" ]; then
      session_term="$(tmux show-environment -t "$session" -s TERMINAL 2>/dev/null | sed -n 's/^TERMINAL=//p' | head -n1)"
      session_normalized="$(_normalize_detected_terminal "$session_term" 2>/dev/null || true)"
      if [ "$session_normalized" != "$detected" ]; then
        tmux set-environment -t "$session" TERMINAL "$detected" 2>/dev/null || true
      fi
    fi
  fi

  [ "$detected" = "$current" ] && return 0

  export TERMINAL="$detected"
  bash "$DOTFILES_DIR/shell/common/gogh/persist.sh" --terminal "$detected" 2>/dev/null || true
  if [ "${TERMINAL_AUTO_DETECT_VERBOSE:-}" = 1 ]; then
    printf 'TERMINAL=%s (auto-detected; default: %s)\n' "$detected" "$default"
  fi
}

# User command: pick, detect, sync, or override TERMINAL for this shell session.
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
      local detected=""
      detected="$(detect_terminal_emulator 2>/dev/null || true)"
      printf 'TERMINAL=%s  default=%s' "${TERMINAL:-$default}" "$default"
      [ -n "$detected" ] && printf '  detected=%s' "$detected"
      printf '\n'
      if [ "${TERMINAL_OVERRIDE:-}" = 1 ]; then
        printf 'Manual override active — run: use-terminal reset\n'
      elif [ -n "$detected" ] && [ "$detected" != "${TERMINAL:-$default}" ]; then
        printf 'Run: use-terminal sync\n'
      fi
      return 0
      ;;
    detect)
      local detected="" cfg=""
      case "${2:-}" in
        --export)
          detected="$(detect_terminal_emulator 2>/dev/null || true)"
          if [ -z "$detected" ]; then
            printf 'could not detect hosting terminal\n' >&2
            return 1
          fi
          printf 'export TERMINAL=%s\n' "$detected"
          return 0
          ;;
        --print|--dry-run)
          detect_terminal_emulator
          return $?
          ;;
      esac
      sync_terminal_to_host 1
      detected="$(detect_terminal_emulator 2>/dev/null || true)"
      if [ -z "$detected" ]; then
        printf 'could not detect hosting terminal\n' >&2
        return 1
      fi
      printf 'detected: %s\n' "$detected"
      printf 'TERMINAL=%s  default=%s\n' "${TERMINAL:-$default}" "$default"
      cfg="$(_terminal_config_path "$detected")"
      if [ -n "$cfg" ] && [ ! -f "$cfg" ]; then
        printf 'Config missing: %s — run ./update.sh\n' "$cfg"
      fi
      return 0
      ;;
    sync)
      local detected=""
      sync_terminal_to_host 1
      detected="$(detect_terminal_emulator 2>/dev/null || true)"
      printf 'TERMINAL=%s  default=%s' "${TERMINAL:-$default}" "$default"
      [ -n "$detected" ] && printf '  detected=%s' "$detected"
      printf '\n'
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

# precmd/PROMPT_COMMAND hook: retry sync until TERMINAL matches detect, then unregister.
_terminal_run_deferred_sync() {
  local detected=""
  sync_terminal_to_host 2>/dev/null || true
  detected="$(detect_terminal_emulator 2>/dev/null || true)"
  if [ -n "$detected" ] && [ "$detected" = "${TERMINAL:-}" ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then
      add-zsh-hook -d precmd _terminal_run_deferred_sync 2>/dev/null || true
    elif [ -n "${BASH_VERSION:-}" ]; then
      unset -f _terminal_run_deferred_sync 2>/dev/null || true
      if [ -n "${PROMPT_COMMAND:-}" ]; then
        PROMPT_COMMAND="${PROMPT_COMMAND//_terminal_run_deferred_sync;}"
        PROMPT_COMMAND="${PROMPT_COMMAND//;_terminal_run_deferred_sync}"
        PROMPT_COMMAND="${PROMPT_COMMAND//_terminal_run_deferred_sync}"
      fi
    fi
  fi
}

# Register _terminal_run_deferred_sync on first prompt (zsh precmd / bash PROMPT_COMMAND).
_terminal_schedule_deferred_sync() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null || return 0
    add-zsh-hook precmd _terminal_run_deferred_sync 2>/dev/null || true
  elif [ -n "${BASH_VERSION:-}" ]; then
    case "${PROMPT_COMMAND:-}" in
      *_terminal_run_deferred_sync*) ;;
      *)
        PROMPT_COMMAND="_terminal_run_deferred_sync${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
        ;;
    esac
  fi
}

# Auto-match TERMINAL when an interactive shell loads (again on first prompt —
# tmux panes sometimes lack TMUX / client info until the shell is fully up).
case "$-" in
  *i*)
    sync_terminal_to_host 2>/dev/null || true
    _terminal_schedule_deferred_sync
    ;;
esac
