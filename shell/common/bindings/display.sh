# Render markdown at the top of the terminal with a small left margin (any window width).
_show_markdown_top_center() {
  local file="$1"
  local cols margin=2 content_width top_pad=2 i

  if [ ! -f "$file" ]; then
    printf 'File not found: %s\n' "$file" >&2
    return 1
  fi

  cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
  content_width=$(( cols - margin * 2 ))
  (( content_width < 40 )) && content_width=40

  if [ -t 1 ]; then
    clear 2>/dev/null || printf '\033[H\033[2J'
  fi

  for ((i = 0; i < top_pad; i++)); do
    printf '\n'
  done

  _show_markdown_render() {
    if command -v bat >/dev/null 2>&1; then
      bat --paging=never --style=auto --color=always --decorations=never \
        --terminal-width="$content_width" "$file"
    else
      cat "$file"
    fi
  }

  while IFS= read -r line; do
    printf '%*s%s\n' "$margin" '' "$line"
  done < <(_show_markdown_render)

  if [ -t 0 ] && [ -r /dev/tty ]; then
    printf '\n'
    printf '%*s%s' "$margin" '' 'Press any key to continue…' >/dev/tty
    # bash: read -n 1 reads one char; zsh: -n is line count — use read -k 1 instead.
    if [ -n "${ZSH_VERSION:-}" ]; then
      read -k 1 -s </dev/tty 2>/dev/null || true
    else
      read -r -n 1 -s </dev/tty 2>/dev/null || true
    fi
    printf '\n' >/dev/tty
  fi
}
