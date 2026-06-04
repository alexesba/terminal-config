# ~/.bashrc: executed by bash(1) for non-login shells.
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

# Auto-create bash_custom.sh from the example template on first run
if [ ! -f "$DOTFILES_DIR/bash-files/bash_custom.sh" ] && \
   [ -f "$DOTFILES_DIR/bash-files/bash_custom.sh.example" ]; then
  cp "$DOTFILES_DIR/bash-files/bash_custom.sh.example" "$DOTFILES_DIR/bash-files/bash_custom.sh"
fi

if [ -f "$DOTFILES_DIR/bash-files/bash_custom.sh" ]; then
  source "$DOTFILES_DIR/bash-files/bash_custom.sh"
fi

export PATH="/usr/local/bin:$PATH"

source "$DOTFILES_DIR/bash-files/os-config.sh"

export NVM_DIR="$HOME/.nvm"
