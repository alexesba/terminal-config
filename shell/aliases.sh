# Built-in aliases shipped with these dotfiles (both shells).
source "$DOTFILES_DIR/shell/aliases/default.sh"

# Optional local alias overrides at ~/.bash_aliases (both bash and zsh).
# Loaded after shell/aliases/default.sh so entries here override repo defaults.
# Skip re-sourcing when the file is just a symlink back to our own defaults.
if [ -f ~/.bash_aliases ]; then
  if [ -L ~/.bash_aliases ] && [[ "$(readlink "$HOME/.bash_aliases")" == *aliases/default.sh ]]; then
    :
  else
    . ~/.bash_aliases
  fi
fi
