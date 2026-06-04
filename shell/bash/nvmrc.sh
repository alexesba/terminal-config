# Auto-switch Node from .nvmrc on directory change (bash has no chpwd hook).
source "$DOTFILES_DIR/shell/common/nvmrc.sh"

if command -v nvm &>/dev/null; then
  _load-nvmrc-bash() {
    [ "$PWD" = "$_NVMRC_PREV_PWD" ] && return
    _NVMRC_PREV_PWD="$PWD"
    load-nvmrc
  }

  PROMPT_COMMAND="_load-nvmrc-bash; $PROMPT_COMMAND"
  _load-nvmrc-bash # also run on shell start for the current directory
fi
