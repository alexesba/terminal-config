# Built-in aliases shipped with these dotfiles (both shells).
source "$DOTFILES_DIR/shell/aliases/default.sh"

# Optional local overrides at ~/.bash_aliases.
# Legacy installs symlinked this file to shell/aliases/default.sh (or the old
# bash_aliases.sh path) — skip re-sourcing when the symlink is just our defaults.
if [ -f ~/.bash_aliases ]; then
  if [ -L ~/.bash_aliases ]; then
    _alias_target="$(readlink "$HOME/.bash_aliases")"
    case "$_alias_target" in
      *aliases/default.sh|*bash_aliases.sh) ;;
      *) . ~/.bash_aliases ;;
    esac
    unset _alias_target
  else
    . ~/.bash_aliases
  fi
fi
