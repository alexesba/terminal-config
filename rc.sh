# ~/.zshrc / ~/.bashrc sources this file via a local wrapper installed by install.sh.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Resolve the dotfiles directory regardless of where the repo lives.
if [ -n "$ZSH_VERSION" ]; then
  # zsh: %x is rc.sh; :A resolves symlinks + makes absolute; :h is dirname
  export DOTFILES_DIR="${${(%):-%x}:A:h}"
else
  # bash: BASH_SOURCE is rc.sh when sourced from the home-directory wrapper
  _src="${BASH_SOURCE[0]}"
  while [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    [[ $_src != /* ]] && _src="$_dir/$_src"
  done
  export DOTFILES_DIR="$(cd -P "$(dirname "$_src")" && pwd)"
  unset _src _dir
fi

# Personal overrides (optional). Seeded by install.sh from shell/custom.sh.example;
# rc.sh sources ~/.custom.sh when present, before loader.sh (themes, TERMINAL, …).
_custom="${HOME}/.custom.sh"
if [ -f "$_custom" ]; then
  source "$_custom"
fi

export PATH="/usr/local/bin:$PATH"

source "$DOTFILES_DIR/shell/loader.sh"
