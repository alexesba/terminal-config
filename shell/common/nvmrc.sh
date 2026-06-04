# Shared .nvmrc auto-switch logic. Shell-specific loaders register the hook:
#   bash/nvmrc.sh  → PROMPT_COMMAND with a PWD guard
#   zsh/nvmrc.sh    → chpwd hook
if command -v nvm &>/dev/null; then
  load-nvmrc() {
    local node_version nvmrc_path nvmrc_node_version
    node_version="$(nvm version)"
    nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      nvmrc_node_version="$(nvm version "$(cat "${nvmrc_path}")")"

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
fi
