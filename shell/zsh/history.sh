# Defaults below; override in ~/.local.sh before loader.sh runs (e.g. HISTFILE, HISTSIZE).
export HISTFILE="${HISTFILE:-${HOME}/.zsh_history}"
export HISTSIZE="${HISTSIZE:-50000}"
export SAVEHIST="${SAVEHIST:-20000}"
setopt EXTENDED_HISTORY       # save timestamp + duration in history file
setopt HIST_FIND_NO_DUPS
setopt INC_APPEND_HISTORY
