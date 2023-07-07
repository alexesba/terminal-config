function fzf_then_open_in_editor() {
  local file=$(fzf)
  C_EDITOR=${EDITOR:-nvim}
  # Open the file if it exists
  if [ -n "$file" ]; then
    # Use the default editor if it's defined, otherwise Vim
    eval $C_EDITOR "$file"
  fi
}
