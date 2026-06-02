# Only register the chpwd hook if nvm is actually loaded
if command -v nvm &>/dev/null; then
  load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc  # also run on shell start for the current directory
fi
