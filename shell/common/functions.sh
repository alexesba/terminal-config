source "$DOTFILES_DIR/lib/tmux_sessions.sh"

function restore_db {
  echo "Importing filename: $2 into database: $1"
  if [ -f "$2" ]; then
    pg_restore --verbose --clean --no-acl --no-owner -d "$1" "$2"
  else
    echo "The file $2 doesn't exist"
  fi
}
