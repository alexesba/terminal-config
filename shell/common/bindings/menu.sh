# Show terminal-config key bindings (shell/common/bindings/bindings.md via bat).
#
#   bindings          — display bindings reference
#   bindings --help
bindings() {
  case "${1:-}" in
    -h|--help|help)
      cat <<EOF
Usage: bindings

  bindings    Show keyboard shortcuts for this dotfiles setup

See also: help (unified menu)
EOF
      return 0
      ;;
  esac
  show_bindings
}

show_bindings() {
  local bindings_md="$DOTFILES_DIR/shell/common/bindings/bindings.md"

  # shellcheck source=display.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/bindings/display.sh"
  _show_markdown_top_center "$bindings_md"
}
