# Auto-switch Node from .nvmrc on directory change.
source "$DOTFILES_DIR/shell/common/nvmrc.sh"

if command -v nvm &>/dev/null; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc # also run on shell start for the current directory
fi
