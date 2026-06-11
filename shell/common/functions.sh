function tmux-start {
  local tmux_dirname tmux_app
  tmux_dirname="${1:-$(pwd)}"

  if test "$tmux_dirname" = "."; then
    tmux_dirname="$(pwd)"
  fi

  tmux_app="$(basename "$tmux_dirname")"

  if ! tmux has-session -t "$tmux_app" 2>/dev/null; then
    echo "No Session found.  Creating and configuring."
    tmux new-session -d -s "$tmux_app" -c "$tmux_dirname" || return
  else
    echo "Session found.  Connecting."
  fi

  sleep 0.5

  tmux attach-session -t "$tmux_app"
}

function restore_db {
  echo "Importing filename: $2 into database: $1"
  if [ -f "$2" ]; then
    pg_restore --verbose --clean --no-acl --no-owner -d "$1" "$2"
  else
    echo "The file $2 doesn't exist"
  fi
}
