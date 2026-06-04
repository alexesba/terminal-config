function fzf_then_open_in_editor() {
  local file
  file=$(fzf </dev/tty)
  # Open the file if it exists
  if [[ -n "$file" ]]; then
    # Use the default editor if it's defined, otherwise Vim
    ${EDITOR:-nvim} "$file"
    zle reset-prompt
  fi
}
