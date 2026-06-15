# Shared Ctrl-O / Ctrl-F file finder for bash and zsh.
fzf_then_open_in_editor() {
  local file preview_cmd editor_name prompt

  # shellcheck source=../fzf/prompts.sh disable=SC1091
  source "$DOTFILES_DIR/shell/common/fzf/prompts.sh"
  prompt=$(_fzf_icon_prompt search)

  editor_name="${EDITOR:-nvim}"
  editor_name="${editor_name##*/}"

  if command -v bat &>/dev/null; then
    # Preview must not read stdin — it shares the TTY with fzf and steals keystrokes.
    preview_cmd='bat --style=numbers --color=always --paging=never --line-range 1:60 {} </dev/null 2>/dev/null || head -60 {} </dev/null'
  else
    preview_cmd='head -60 {} </dev/null'
  fi

  if [ -n "${ZSH_VERSION:-}" ]; then
    emulate -L zsh
    setopt localoptions pipefail 2>/dev/null
    zle -I
  fi

  file="$(
    FZF_DEFAULT_OPTS= eval "${FZF_DEFAULT_COMMAND:-find . -type f}" | fzf \
      --ansi \
      --layout=reverse \
      --height=85% \
      --min-height=10 \
      --margin=0,4% \
      --border=rounded \
      --border-label=$'\033[1;36m files \033[0m' \
      --header='Enter opens in '"$editor_name"' · Esc cancels' \
      --prompt="$prompt" \
      --preview-window='right:58%:border-left' \
      --preview="$preview_cmd" \
      --bind='ctrl-/:toggle-preview'
  )" </dev/tty || return

  [ -n "$file" ] || return
  "${EDITOR:-nvim}" "$file"

  if [[ -n "${ZSH_VERSION:-}" && -n "${WIDGET:-}" ]]; then
    zle reset-prompt
  fi
}
