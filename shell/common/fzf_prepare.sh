# Drop stray TTY bytes before fzf reads /dev/tty.
# Kitty/macOS Alt sends ESC then the key; zle/readline can leave ^[h on the line
# and block fzf until Esc clears the queue.
_fzf_prepare_tty() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    emulate -L zsh 2>/dev/null
    setopt localoptions pipefail 2>/dev/null
    zle -I 2>/dev/null
  fi

  if [ -t 0 ] && [ -r /dev/tty ] 2>/dev/null; then
    local _b
    while read -r -t 0.001 -n 256 _b </dev/tty 2>/dev/null; do
      :
    done
  fi
}
