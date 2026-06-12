# Re-source ~/.zshrc or ~/.bashrc in the current shell (call-time shell detection).

reload_interactive_shell() {
  if [ -n "${ZSH_VERSION:-}" ] && [ -f "${HOME}/.zshrc" ]; then
    # shellcheck source=/dev/null
    source "${HOME}/.zshrc"
  elif [ -n "${BASH_VERSION:-}" ] && [ -f "${HOME}/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc"
  else
    printf 'No ~/.zshrc or ~/.bashrc found.\n' >&2
    return 1
  fi
}

reload() {
  reload_interactive_shell "$@"
}
