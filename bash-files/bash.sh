# #load common functions
source "$DOTFILES_DIR/bash-files/common-functions.sh"
source "$DOTFILES_DIR/bash-files/bash/functions.sh"
source "$DOTFILES_DIR/bash-files/bash/bindings.sh"
source "$DOTFILES_DIR/bash-files/bash/fzf-config.sh"
source "$DOTFILES_DIR/bash-files/bash/nvm.sh"
source "$DOTFILES_DIR/bash-files/bash/nvmrc.sh"
source "$DOTFILES_DIR/bash-files/bash/history.sh"
source "$DOTFILES_DIR/bash-files/bash/autocomplete.sh"
source "$DOTFILES_DIR/bash-files/bash/pyenv.sh"
# Sourced last among PROMPT_COMMAND contributors so its $? capture runs first.
source "$DOTFILES_DIR/bash-files/bash/ps1.sh"

source "$DOTFILES_DIR/bash-files/aliases.sh"
source "$DOTFILES_DIR/bash-files/dircolors.sh"
source "$DOTFILES_DIR/bash-files/rbenv.sh"
