function tmux-start {
  local tmux_dirname tmux_app
  tmux_dirname="${1:-$(pwd)}"

  if test "$tmux_dirname" = "."; then
    tmux_dirname="$(pwd)"
  fi

  tmux_app="$(basename "$tmux_dirname")"

  if ! tmux has-session -t "$tmux_app" 2>/dev/null; then
    echo "No Session found.  Creating and configuring."
    pushd "$tmux_dirname" || return
    tmux new-session -d -s "$tmux_app"
    popd || return
  else
    echo "Session found.  Connecting."
  fi

  sleep 0.5

  tmux attach-session -t "$tmux_app"
}
function colorscheme() {
  # GOGH_DIR points at the Gogh repo root (matches bootstrap.sh); themes live in
  # its installs/ subdirectory.
  local gogh_dir="${GOGH_DIR:-$HOME/src/gogh}/installs"
  if [ ! -d "$gogh_dir" ]; then
    echo "gogh themes not found at $gogh_dir"
    echo "Clone it: git clone https://github.com/Gogh-Co/Gogh ~/src/gogh"
    echo "Or set GOGH_DIR in bash_custom.sh to point to your Gogh checkout."
    return 1
  fi
  local preview_script="$DOTFILES_DIR/bash-files/gogh-preview.sh"
  local persist_script="$DOTFILES_DIR/bash-files/gogh-persist.sh"

  # Build a "Human Name<TAB>file.sh" list (one awk pass): show each theme's
  # PROFILE_NAME, falling back to a prettified filename. fzf displays only the
  # name (--with-nth=1) but returns the real filename (--accept-nth=2).
  local selection
  selection=$(awk -F'"' '
    function flush() {
      if (curfile != "") {
        if (pname != "") disp = pname
        else { disp = base; sub(/\.sh$/, "", disp); gsub(/-/, " ", disp) }
        printf "%s\t%s\n", disp, base
      }
    }
    FNR == 1 { flush(); curfile = FILENAME; pname = ""; n = split(FILENAME, a, "/"); base = a[n] }
    /^export PROFILE_NAME=/ { pname = $2 }
    END { flush() }
  ' "$gogh_dir"/*.sh | sort -f | fzf \
    --delimiter='\t' --with-nth=1 --accept-nth=2 \
    --prompt='colorscheme> ' \
    --preview "bash '$preview_script' '$gogh_dir'/{2}" \
    --preview-window='right:65%:wrap') || return

  [ -z "$selection" ] && return
  sh "$gogh_dir/$selection"
  # Persist the choice so it survives new terminal windows (e.g. WezTerm, which
  # gogh otherwise only themes for the current session).
  [ -f "$persist_script" ] && bash "$persist_script" "$gogh_dir/$selection" "${TERMINAL:-}"
}

function restore_db {
  echo "Importing filename: $2 into database: $1"
  if [ -f "$2" ]; then
    pg_restore --verbose --clean --no-acl --no-owner -d "$1" "$2"
  else
    echo "The file $2 doesn't exist"
  fi
}
