function tmux-start {
  TMUX_DIRNAME=${1:-$(pwd)}

  if test "$TMUX_DIRNAME" = "."; then
    TMUX_DIRNAME=$(pwd)
  fi

  TMUX_APP=$(basename $TMUX_DIRNAME)

  tmux has-session -t $TMUX_APP 2>/dev/null

  if [ "$?" -eq 1 ] ; then
    echo "No Session found.  Creating and configuring."
    pushd $TMUX_DIRNAME
    tmux new-session -d -s $TMUX_APP
    popd
  else
    echo "Session found.  Connecting."
  fi

  sleep 0.5

  tmux attach-session -t $TMUX_APP
}

# Load nvmrc if exist under the current directory
loadnvmrc() {
  if [[ $PWD == $PREV_PWD ]]; then
    return
  fi

  PREV_PWD=$PWD

  if [[ -f "$PWD/.nvmrc" ]]; then
    nvm use
  fi
}

function colorscheme() {
  local gogh_dir="${GOGH_DIR:-$HOME/src/gogh/installs}"
  if [ ! -d "$gogh_dir" ]; then
    echo "gogh not found at $gogh_dir"
    echo "Clone it: git clone https://github.com/Gogh-Co/Gogh ~/src/gogh"
    echo "Or set GOGH_DIR in bash_custom.sh to point to your install."
    return 1
  fi
  local dotfiles="${DOTFILES_DIR:-$HOME/Projects/terminal-config}"
  local preview_script="$dotfiles/bash-files/gogh-preview.sh"
  local persist_script="$dotfiles/bash-files/gogh-persist.sh"

  local selection
  selection=$(ls "$gogh_dir" | grep '\.sh$' | fzf \
    --prompt='colorscheme> ' \
    --preview "bash '$preview_script' '$gogh_dir'/{}" \
    --preview-window='right:65%:wrap') || return

  [ -z "$selection" ] && return
  sh "$gogh_dir/$selection"
  # Persist the choice so it survives new terminal windows (e.g. WezTerm, which
  # gogh otherwise only themes for the current session).
  [ -f "$persist_script" ] && bash "$persist_script" "$gogh_dir/$selection" "${TERMINAL:-}"
}

function restore_db {
  echo "Importing filename: $2 into database: $1"
  if [ -f $2 ]; then
    pg_restore --verbose --clean --no-acl --no-owner  -d $1 $2
  else
    echo "The file $2 doesn't exist"
  fi
}
