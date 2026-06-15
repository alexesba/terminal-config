# Nerd Font glyphs for fzf --prompt (terminal must use a Nerd Font).
# https://www.nerdfonts.com/cheat-sheet

_fzf_prompt_glyph() {
  case "$1" in
    help)     printf '\uf128' ;;  # nf-fa-question
    gear)     printf '\uf013' ;;  # nf-fa-gear
    search)   printf '\uf002' ;;  # nf-fa-magnifying_glass
    terminal) printf '\ue795' ;;  # nf-dev-terminal (Caskaydia / devicons)
  esac
}

# Cyan bold icon prompt, e.g. "  > "
_fzf_icon_prompt() {
  printf '\033[1;36m%s\033[0m> ' "$(_fzf_prompt_glyph "$1")"
}
