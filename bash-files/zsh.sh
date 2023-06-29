bindkey -e

if which zsh > /dev/null; then
  export SHELL=$(which zsh)
fi



# #load common functions
source ~/.config/terminal-config/bash-files/zsh/functions.sh
source ~/.config/terminal-config/bash-files/zsh/bindings.sh
source ~/.config/terminal-config/bash-files/zsh/fzf-config.sh
source ~/.config/terminal-config/bash-files/zsh/nvm.sh
source ~/.config/terminal-config/bash-files/zsh/ps1.sh
source ~/.config/terminal-config/bash-files/zsh/nvmrc.sh
source ~/.config/terminal-config/bash-files/zsh/autocomplete.sh

source ~/.config/terminal-config/bash-files/aliases.sh
source ~/.config/terminal-config/bash-files/dircolors.sh
source ~/.config/terminal-config/bash-files/rbenv.sh
