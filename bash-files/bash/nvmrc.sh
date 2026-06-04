# Auto-switch the Node version from a directory's .nvmrc on change. Mirrors
# zsh/nvmrc.sh (which uses a chpwd hook); bash has no chpwd, so we run it from
# PROMPT_COMMAND with a PWD guard to only act when the directory changes.
if command -v nvm &>/dev/null; then
  load-nvmrc() {
    [ "$PWD" = "$_NVMRC_PREV_PWD" ] && return
    _NVMRC_PREV_PWD="$PWD"

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

  PROMPT_COMMAND="load-nvmrc; $PROMPT_COMMAND"
  load-nvmrc # also run on shell start for the current directory
fi
