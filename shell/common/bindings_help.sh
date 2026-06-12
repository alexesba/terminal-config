#!/usr/bin/env bash
# Key binding reference for terminal-config + fzf defaults.
#
#   bindings_help.sh list   — rows for fzf (key<TAB>description)
set -u

_bindings_help_rows() {
  cat <<'EOF'
help	Unified menu — edit configs, bindings, colorscheme, use-terminal
config	Edit config files only
bindings	Show key bindings only
colorscheme	Fuzzy-pick and apply a Gogh theme
use-terminal	Switch colorscheme target terminal
Ctrl+O	Find file in current directory → $EDITOR
Ctrl+F	Find file in current directory → $EDITOR
Ctrl+T	Fuzzy find files (fzf installer)
Ctrl+R	Fuzzy search command history (fzf installer)
Ctrl+Space	Accept autosuggestion (zsh + autosuggestions)
↑ / ↓	History prefix search
Note	Ctrl+S / Ctrl+H / Ctrl+B are not used — flow control, backspace, or tmux prefix
EOF
}

case "${1:-}" in
  list) _bindings_help_rows ;;
  *)
    printf 'Usage: %s list\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
