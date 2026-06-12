# Show terminal-config key bindings in an fzf read-only list.
#
#   bindings          — fzf menu (Alt+H)
#   bindings --help
bindings() {
  case "${1:-}" in
    -h|--help|help)
      cat <<EOF
Usage: bindings

  bindings    List keyboard shortcuts for this dotfiles setup

See also: help (unified menu)
EOF
      return 0
      ;;
  esac
  show_bindings
}

show_bindings() {
  local help_script

  # shellcheck source=shell/common/fzf_prepare.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/fzf_prepare.sh"
  _fzf_prepare_tty

  command -v fzf >/dev/null 2>&1 || {
    bash "$DOTFILES_DIR/shell/common/bindings_help.sh" list
    return 0
  }

  help_script="$DOTFILES_DIR/shell/common/bindings_help.sh"

  bash "$help_script" list | fzf \
    --ansi \
    --layout=reverse \
    --height=85% \
    --min-height=12 \
    --margin=0,4% \
    --border=rounded \
    --delimiter=$'\t' \
    --with-nth=1,2 \
    --header='Key bindings · Enter/Esc to close · Or run: help · bindings' \
    --prompt='bindings> ' \
    --bind='enter:accept' \
    --bind='double-click:accept' \
    </dev/tty >/dev/null || true

  if [ -n "${ZSH_VERSION:-}" ]; then
    zle reset-prompt
  fi
}
