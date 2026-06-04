# ~/.zshrc / ~/.bashrc entry point (symlinked from this repo as rc.sh).
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Resolve the dotfiles directory regardless of where the repo lives. The rc file
# is a symlink into the repo, so we must follow symlinks to find the real path.
if [ -n "$ZSH_VERSION" ]; then
  # zsh: %x is this file; :A resolves symlinks + makes absolute; :h is dirname
  export DOTFILES_DIR="${${(%):-%x}:A:h}"
else
  # bash: BASH_SOURCE is the (symlinked) rc path, so walk the symlink chain
  _src="${BASH_SOURCE[0]}"
  while [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    [[ $_src != /* ]] && _src="$_dir/$_src"
  done
  export DOTFILES_DIR="$(cd -P "$(dirname "$_src")" && pwd)"
  unset _src _dir
fi

# Personal overrides — migrate from pre-rename paths on first run
_custom="$DOTFILES_DIR/shell/custom.sh"
if [ ! -f "$_custom" ]; then
  if [ -f "$DOTFILES_DIR/bash-files/bash_custom.sh" ]; then
    cp "$DOTFILES_DIR/bash-files/bash_custom.sh" "$_custom"
  elif [ -f "$DOTFILES_DIR/shell/bash_custom.sh" ]; then
    cp "$DOTFILES_DIR/shell/bash_custom.sh" "$_custom"
  elif [ -f "$DOTFILES_DIR/shell/custom.sh.example" ]; then
    cp "$DOTFILES_DIR/shell/custom.sh.example" "$_custom"
  fi
fi

if [ -f "$_custom" ]; then
  source "$_custom"
fi

export PATH="/usr/local/bin:$PATH"

source "$DOTFILES_DIR/shell/loader.sh"
