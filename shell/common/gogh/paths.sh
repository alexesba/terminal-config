# Gogh repo paths, TERMINAL resolution for colorscheme, and theme apply helper.
# Sourced from colorscheme.sh (interactive shell with DOTFILES_DIR set).

# shellcheck source=../../../lib/helpers.sh disable=SC1091
source "${DOTFILES_DIR:?DOTFILES_DIR}/lib/helpers.sh"
# shellcheck source=../terminal/detect.sh disable=SC1091
source "${DOTFILES_DIR}/shell/common/terminal/detect.sh"

# Print Gogh repo root (normalizes GOGH_DIR when it mistakenly points at installs/).
gogh_repo_root() {
  local root="${GOGH_DIR:-$HOME/src/gogh}"
  if [ -f "$root/apply-colors.sh" ]; then
    printf '%s\n' "$root"
    return 0
  fi
  if [ "$(basename "$root")" = installs ] && [ -f "$(dirname "$root")/apply-colors.sh" ]; then
    (cd "$(dirname "$root")" && pwd)
    return 0
  fi
  printf '%s\n' "$root"
}

# Print Gogh installs/ directory.
gogh_installs_dir() {
  printf '%s/installs\n' "$(gogh_repo_root)"
}

# True when WezTerm env vars indicate the hosting terminal (common in WSL panes).
_gogh_host_is_wezterm() {
  hosting_wezterm_p
}

# Resolve alacritty|kitty|wezterm for colorscheme / apply_saved.
# Hosting terminal env wins over a stale TERMINAL in ~/.local.sh.
gogh_resolve_terminal() {
  local term="${TERMINAL:-}"

  if hosting_kitty_p; then
    printf 'kitty\n'
    return 0
  fi
  if hosting_alacritty_p; then
    printf 'alacritty\n'
    return 0
  fi
  if _gogh_host_is_wezterm; then
    printf 'wezterm\n'
    return 0
  fi

  if [ -z "$term" ]; then
    term="$(detect_terminal_emulator 2>/dev/null || true)"
  fi
  if [ -z "$term" ]; then
    term="$(custom_export_value "$(local_sh_path)" TERMINAL 2>/dev/null || true)"
  fi
  printf '%s\n' "${term:-wezterm}"
}

# Run a Gogh theme script (kitty/alacritty apply). Returns 1 when apply-colors.sh is missing.
gogh_apply_theme_script() {
  local gogh_root="$1" theme_file="$2" term="$3"
  local apply installs

  apply="$gogh_root/apply-colors.sh"
  if [ ! -f "$apply" ]; then
    printf 'Gogh checkout incomplete: missing %s\n' "$apply" >&2
    printf 'Fix: colorscheme update   or   ./bootstrap.sh --gogh\n' >&2
    if is_wsl && [ "$term" != wezterm ]; then
      printf 'WSL: set TERMINAL and config paths in ~/.local.sh (re-run install.sh on WSL).\n' >&2
    fi
    return 1
  fi

  installs="$(dirname "$theme_file")"
  gogh_export_terminal_env "$term"
  GOGH_APPLY_SCRIPT="$apply" \
  SCRIPT_PATH="$installs" \
  TERMINAL="$term" \
    bash "$theme_file"
}
