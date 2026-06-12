# Resolve $EDITOR to an executable on PATH (handles bare "nvim" when Homebrew isn't inherited).
_resolve_editor() {
  local candidate resolved
  for candidate in "${EDITOR:-}" "${VISUAL:-}" nvim vim vi nano; do
    [ -n "$candidate" ] || continue
    resolved=$(command -v "$candidate" 2>/dev/null) || continue
    printf '%s' "$resolved"
    return 0
  done
  printf 'No editor found. Set EDITOR in ~/.local.sh (e.g. export EDITOR=/opt/homebrew/bin/nvim)\n' >&2
  return 1
}

# zle reset-prompt only when invoked from a key widget (not plain `help` / `config` commands).
_zle_reset_prompt_if_active() {
  [[ -n "${ZSH_VERSION:-}" && -n "${WIDGET:-}" ]] || return 0
  zle reset-prompt
}
