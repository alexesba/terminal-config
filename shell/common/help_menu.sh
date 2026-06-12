# Unified fzf menu: edit configs, show bindings, colorscheme, use-terminal.
#
#   help              — main menu (bash: help CMD still uses the shell builtin)
#   help --help

_help_usage() {
  cat <<EOF
Usage: help

  help    Open a fuzzy menu of dotfiles actions and editable config files

Also available directly: config, bindings, colorscheme, use-terminal
EOF
}

_help_run_action() {
  local action="$1"

  case "$action" in
    edit:*)
      config_open_file "${action#edit:}"
      ;;
    bindings)
      show_bindings
      ;;
    colorscheme)
      colorscheme
      ;;
    use-terminal)
      use-terminal
      ;;
    *)
      printf 'Unknown action: %s\n' "$action" >&2
      return 1
      ;;
  esac
}

help_menu() {
  local list_script preview_script selection

  # shellcheck source=shell/common/fzf_prepare.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/fzf_prepare.sh"
  _fzf_prepare_tty

  command -v fzf >/dev/null 2>&1 || {
    printf 'fzf not found — install via ./bootstrap.sh --fzf\n' >&2
    printf 'Try: config · bindings · colorscheme · use-terminal\n' >&2
    return 1
  }

  list_script="$DOTFILES_DIR/shell/common/help_list.sh"
  preview_script="$DOTFILES_DIR/shell/common/help_preview.sh"

  selection="$(
    bash "$list_script" rows | fzf \
      --ansi \
      --layout=reverse \
      --height=85% \
      --min-height=12 \
      --margin=0,4% \
      --border=rounded \
      --delimiter=$'\t' \
      --with-nth=4 \
      --accept-nth=2 \
      --header='help — pick an action or config file · Enter runs/opens · Esc cancels' \
      --prompt='help> ' \
      --preview-window='right:55%:border-left' \
      --preview="bash '$preview_script' {2} {3}" \
      --bind='ctrl-/:toggle-preview'
  )" </dev/tty || return 0

  [ -n "$selection" ] || return 0
  _help_run_action "$selection"
}

help() {
  if [ -n "${BASH_VERSION:-}" ] && [ $# -gt 0 ]; then
    case "$1" in
      -h|--help)
        _help_usage
        return 0
        ;;
      *)
        command help "$@"
        return
        ;;
    esac
  fi

  case "${1:-}" in
    -h|--help)
      _help_usage
      return 0
      ;;
  esac

  help_menu
}
