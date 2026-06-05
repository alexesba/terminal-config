# Built-in aliases shipped with these dotfiles (both shells).
source "$DOTFILES_DIR/shell/aliases/default.sh"

# Optional local overrides at ~/.bash_aliases.
# Skip re-sourcing when the file is just a symlink back to our own defaults.
if [ -f ~/.bash_aliases ]; then
  if [ -L ~/.bash_aliases ] && [[ "$(readlink "$HOME/.bash_aliases")" == *aliases/default.sh ]]; then
    :
  else
    . ~/.bash_aliases
  fi
fi
