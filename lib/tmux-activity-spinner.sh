#!/bin/sh
# One-frame tmux tab activity spinner (called from window-status-format).
# Installed to ~/.tmux/activity-spinner.sh by install.sh.
exec </dev/null
case $(($(date +%S) % 4)) in
  0) printf '◴' ;;
  1) printf '◷' ;;
  2) printf '◶' ;;
  *) printf '◵' ;;
esac
