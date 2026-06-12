# Interactive TTY tweaks shared by bash and zsh.
if [ -t 0 ]; then
  # Ctrl+S sends XOFF (pause output) by default — freezes the terminal until Ctrl+Q.
  stty -ixon 2>/dev/null || true
fi
