# Fuzzy-pick a personal config file and open it in $EDITOR.
#
#   config          — config file picker (also in: help)
#   config --help
config() {
  case "${1:-}" in
    -h|--help|help)
      cat <<EOF
Usage: config

  config    Open a fuzzy picker of editable dotfiles (~/.local.sh, ~/.tmux.conf, …)

See also: help (unified menu with bindings, colorscheme, and config files)
EOF
      return 0
      ;;
  esac
  config_edit
}

# Open a config path in \$EDITOR (shared by config_edit and help menu).
config_open_file() {
  local path="$1"
  local editor="${EDITOR:-${VISUAL:-nvim}}"

  case "$path" in
    "$HOME/.bash_aliases")
      if [ ! -e "$path" ]; then
        touch "$path"
      fi
      ;;
    "$HOME/.local.sh")
      if [ ! -e "$path" ]; then
        cp "$DOTFILES_DIR/shell/local.sh.example" "$path"
      fi
      ;;
  esac

  if [ ! -e "$path" ]; then
    printf 'File not found: %s\n' "$path" >&2
    printf 'Run ./update.sh to copy templates, or re-run install.sh.\n' >&2
    return 1
  fi

  "$editor" "$path"
}

config_edit() {
  local list_script selection preview_cmd editor

  # shellcheck source=shell/common/fzf_prepare.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/fzf_prepare.sh"
  _fzf_prepare_tty

  command -v fzf >/dev/null 2>&1 || {
    printf 'fzf not found — install via ./bootstrap.sh --fzf\n' >&2
    return 1
  }

  list_script="$DOTFILES_DIR/shell/common/config_list.sh"
  editor="${EDITOR:-${VISUAL:-nvim}}"

  if command -v bat &>/dev/null; then
    preview_cmd='bat --style=numbers --color=always --paging=never --line-range 1:40 {} 2>/dev/null || head -40 {}'
  else
    preview_cmd='head -40 {}'
  fi

  selection="$(
    bash "$list_script" rows | fzf \
      --ansi \
      --layout=reverse \
      --height=85% \
      --min-height=10 \
      --margin=0,4% \
      --border=rounded \
      --delimiter=$'\t' \
      --with-nth=1,3 \
      --accept-nth=2 \
      --header='Settings — pick a config file · Enter opens in '"$editor"' · Esc cancels' \
      --prompt='config> ' \
      --preview-window='right:55%:border-left' \
      --preview="$preview_cmd" \
      --bind='ctrl-/:toggle-preview'
  )" </dev/tty || return 0

  [ -n "$selection" ] || return 0
  config_open_file "$selection"

  if [ -n "${ZSH_VERSION:-}" ]; then
    zle reset-prompt
  fi
}
