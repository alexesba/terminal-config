# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Resolve the dotfiles directory regardless of where the repo lives
if [ -n "$ZSH_VERSION" ]; then
  export DOTFILES_DIR="${${(%):-%x}:A:h}"
else
  export DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -f "$DOTFILES_DIR/bash-files/bash_custom.sh" ]; then
  source "$DOTFILES_DIR/bash-files/bash_custom.sh"
fi

export PATH="/usr/local/bin:$PATH"

source "$DOTFILES_DIR/bash-files/os-config.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
