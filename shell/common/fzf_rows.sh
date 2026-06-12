# Fixed-width label column for fzf menus (label + hint align in the list).
# Uses ASCII column separator so fzf does not collapse spaces; width is character-based.
_fzf_row_display() {
  local width="$1" label="$2" hint="$3" pad
  pad=$(( width - ${#label} ))
  (( pad < 0 )) && pad=0
  printf '%s%*s  %s' "$label" "$pad" '' "$hint"
}
