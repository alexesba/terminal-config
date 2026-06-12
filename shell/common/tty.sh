# Interactive TTY tweaks shared by bash and zsh.
if [ -t 0 ]; then
  # Ctrl+S is XOFF (pause output) by default — freezes the terminal and blocks our
  # config picker binding. Disable so Ctrl+S reaches the shell.
  stty -ixon 2>/dev/null || true
fi
