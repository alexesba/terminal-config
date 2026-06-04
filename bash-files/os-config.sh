#Load custom methods by OS type

if [ -n "$ZSH_VERSION" ]; then
  export SHELL=$(which zsh)
  source "$DOTFILES_DIR/bash-files/zsh.sh"
else
  export SHELL=$(which bash)
  source "$DOTFILES_DIR/bash-files/bash.sh"
fi
