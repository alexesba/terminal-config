#!/bin/sh
# Clear tmux-resurrect snapshot when the last session closes.
# Installed to ~/.tmux/clear-resurrect-when-empty.sh by install.sh.
#
# With @continuum-restore off, nothing auto-restores on server start. Clearing
# the save here means prefix + Ctrl-r also has nothing to bring back after you
# intentionally exit every session.
exec </dev/null
[ -n "$(tmux list-sessions 2>/dev/null)" ] && exit 0
resurrect_dir="${HOME}/.tmux/resurrect"
[ -d "$resurrect_dir" ] || exit 0
rm -f "${resurrect_dir}/last"
