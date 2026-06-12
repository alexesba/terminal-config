# Faster ESC disambiguation — helps Alt/Meta when terminal sends ESC-prefix keys.
bind 'set keyseq-timeout 50'

bind -x '"\C-o": fzf_then_open_in_editor'
bind -x '"\C-f": fzf_then_open_in_editor'
# Note to get rid of a line just Ctrl-C
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
