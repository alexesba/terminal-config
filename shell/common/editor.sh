# zle reset-prompt only when invoked from a key widget (not plain `help` / `config` commands).
_zle_reset_prompt_if_active() {
  [[ -n "${ZSH_VERSION:-}" && -n "${WIDGET:-}" ]] || return 0
  zle reset-prompt
}
