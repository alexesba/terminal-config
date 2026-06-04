# Load shell-specific configuration (bash or zsh).

if [ -n "$ZSH_VERSION" ]; then
  export SHELL=$(which zsh)
  source "$DOTFILES_DIR/shell/zsh.sh"
else
  export SHELL=$(which bash)
  source "$DOTFILES_DIR/shell/bash.sh"
fi
