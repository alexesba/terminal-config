export HISTFILE=~/.bash_history
export HISTFILESIZE=1000000
export HISTSIZE=1000000
export HISTIGNORE='&:exit:x:q:history:gs*:gco:gb:pwd:editenv:ag'
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend # append to history, don't overwrite it
# Share history across sessions cheaply: append this session's new lines to the
# file (-a), then read any new lines other sessions appended (-n). Avoids the
# costly clear+full-reload (history -c; history -r) on every prompt.
PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"
