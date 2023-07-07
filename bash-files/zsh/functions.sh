function fzf_then_open_in_editor() {
  file=$(fzf </dev/tty)
  # Open the file if it exists
  if [[ -n "$file" ]]; then
    # Use the default editor if it's defined, otherwise Vim
    $EDITOR "$file"
    zle reset-prompt
  fi
}
