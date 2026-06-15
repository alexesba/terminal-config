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
  local target="$1"

  case "$target" in
    "$HOME/.bash_aliases")
      if [ ! -e "$target" ]; then
        touch "$target"
      fi
      ;;
    "$HOME/.local.sh")
      if [ ! -e "$target" ]; then
        cp "$DOTFILES_DIR/shell/local.sh.example" "$target"
      fi
      ;;
  esac

  if [ ! -e "$target" ]; then
    printf 'File not found: %s\n' "$target" >&2
    printf 'Run ./update.sh to copy templates, or re-run install.sh.\n' >&2
    return 1
  fi

  "${EDITOR:-nvim}" "$target"
}

config_edit() {
  local list_script preview_script selection editor_name prompt

  # shellcheck source=shell/common/fzf_prompts.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/fzf_prompts.sh"
  prompt=$(_fzf_icon_prompt gear)

  command -v fzf >/dev/null 2>&1 || {
    printf 'fzf not found — install via ./bootstrap.sh --fzf\n' >&2
    return 1
  }

  list_script="$DOTFILES_DIR/shell/common/config_list.sh"
  preview_script="$DOTFILES_DIR/shell/common/config_preview.sh"
  editor_name="${EDITOR:-nvim}"
  editor_name="${editor_name##*/}"

  selection="$(
    bash "$list_script" rows | fzf \
      --ansi \
      --layout=reverse \
      --height=85% \
      --min-height=10 \
      --margin=0,4% \
      --border=rounded \
      --border-label=$'\033[1;36m config \033[0m' \
      --delimiter=$'\t' \
      --with-nth=4 \
      --accept-nth=2 \
      --header='Settings — pick a config file · Enter opens in '"$editor_name"' · Esc cancels' \
      --prompt="$prompt" \
      --preview-window='right:55%:border-left' \
      --preview="bash '$preview_script' {2} {3}" \
      --bind='ctrl-/:toggle-preview'
  )" </dev/tty || return 0

  [ -n "$selection" ] || return 0
  config_open_file "$selection"
}
