#!/usr/bin/env bash
# Format theme rows / header for the colorscheme fzf picker.
#
# Header (colorized active theme name for --header):
#   list.sh header <theme.sh> <display_name>
#
# List rows (mark active theme with ●):
#   list.sh <gogh_installs_dir> <current_file> <current_name>
# Reads "display<TAB>file" lines from stdin.
set -u

# Parse a color export from theme file $1.
theme_field() {
  local theme="$1" var="$2"
  sed -n "s/^export ${var}=\"\(#[0-9A-Fa-f]\{6\}\)\".*/\1/p" "$theme" | head -n1
}

# "#RRGGBB" → "R;G;B" for true-color SGR.
rgb() {
  local h=${1#\#}
  printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# Paint $2 with theme $1 background/foreground for fzf header.
colorize_label() {
  local theme="$1" label="$2"
  local bg fg bgseq fgseq reset bold
  reset=$'\e[0m'
  bold=$'\e[1m'
  bg=$(theme_field "$theme" BACKGROUND_COLOR)
  fg=$(theme_field "$theme" FOREGROUND_COLOR)
  [ -z "$bg" ] && bg="#1a1a1a"
  [ -z "$fg" ] && fg="#d0d0d0"
  bgseq=$(rgb "$bg")
  fgseq=$(rgb "$fg")
  printf '%s%s%s%s%s' \
    "$bold" \
    $'\e[48;2;'"${bgseq}"'m' \
    $'\e[38;2;'"${fgseq}"'m' \
    "$label" \
    "$reset"
}

if [ "${1:-}" = header ]; then
  theme="${2:-}"
  label="${3:-}"
  dim=$'\e[2m'
  reset=$'\e[0m'
  if [ -f "$theme" ] && [ -n "$label" ]; then
    printf 'Active theme: %s%s%s' "$dim" "$(colorize_label "$theme" "$label")" "$reset"
  elif [ -n "$label" ]; then
    printf 'Active theme: %s' "$label"
  else
    printf 'Active theme: unknown'
  fi
  exit 0
fi

gogh_dir="${1:?gogh installs dir required}"
cur_file="${2:-}"
cur_name="${3:-}"

while IFS=$'\t' read -r disp file || [[ -n "$disp" ]]; do
  [ -z "$file" ] && continue
  if [[ "$file" == "$cur_file" || "$disp" == "$cur_name" ]]; then
    printf '● %s\t%s\n' "$disp" "$file"
  else
    printf '  %s\t%s\n' "$disp" "$file"
  fi
done
