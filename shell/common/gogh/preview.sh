#!/usr/bin/env bash
# Render a live, true-color preview of a Gogh theme for fzf's preview pane.
# It only *reads* the hex values from the theme file; it never sources/applies
# the theme, so scrolling the list will not repaint your real terminal.
#
# Usage: preview.sh /path/to/theme.sh
set -u

file="${1:-}"
[ -f "$file" ] || { printf 'No preview available\n'; exit 0; }

# Parse "#RRGGBB" from theme export $1 without executing the file.
field() {
  sed -n "s/^export $1=\"\(#[0-9A-Fa-f]\{6\}\)\".*/\1/p" "$file" | head -n1
}

name=$(sed -n 's/^export PROFILE_NAME="\([^"]*\)".*/\1/p' "$file" | head -n1)
[ -z "$name" ] && name=$(basename "$file" .sh)
bg=$(field BACKGROUND_COLOR)
fg=$(field FOREGROUND_COLOR)
cursor=$(field CURSOR_COLOR)
[ -z "$bg" ] && bg="#1a1a1a"
[ -z "$fg" ] && fg="#d0d0d0"

declare -a COLORS
for i in $(seq -w 1 16); do
  COLORS[10#$i]=$(field "COLOR_$i")
done

reset=$'\e[0m'

# Convert "#RRGGBB" to "R;G;B" for true-color SGR sequences.
rgb() {
  local h=${1#\#}
  printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

bgseq=$(rgb "$bg")
fgseq=$(rgb "$fg")
on=$'\e['"48;2;${bgseq}m"$'\e['"38;2;${fgseq}m"   # paint theme bg + theme fg
# Set foreground to palette color $1 (true-color SGR).
fgc() { printf '\e[38;2;%sm' "$(rgb "$1")"; }

# fzf sets FZF_PREVIEW_COLUMNS / FZF_PREVIEW_LINES for the preview pane.
pane_cols=${FZF_PREVIEW_COLUMNS:-80}
pane_lines=${FZF_PREVIEW_LINES:-24}

# Scale the mock terminal to the preview pane (top half of a fullscreen fzf).
W=$((pane_cols * 82 / 100 - 2))
((W < 56)) && W=56
((W > 120)) && W=120

# Palette swatch geometry (width × height in terminal cells).
SWATCH_W=$(((pane_cols * 62 / 100 - 10) / 8))
((SWATCH_W < 5)) && SWATCH_W=5
((SWATCH_W > 11)) && SWATCH_W=11
SWATCH_H=2

# String length ignoring ANSI escape sequences.
visible_len() {
  local plain
  plain=$(printf '%s' "$1" | sed $'s/\x1b\\[[0-9;]*m//g')
  printf '%s' "${#plain}"
}

# Center a line within FZF_PREVIEW_COLUMNS.
print_centered() {
  local line="$1" lpad
  lpad=$(((pane_cols - $(visible_len "$line")) / 2))
  ((lpad < 0)) && lpad=0
  printf '%*s%s\n' "$lpad" "" "$line"
}

# Draw mock terminal window + palette swatches; output via stdout for fzf preview.
_render_preview() {
  local hr dot arr bold
  local c_red c_grn c_yel c_blu c_mag c_cyn

  bold=$'\e[1m'

  row() {
    local s="$1" plain pad
    plain=$(printf '%s' "$s" | sed $'s/\x1b\\[[0-9;]*m//g')
    pad=$((W - ${#plain}))
    ((pad < 0)) && pad=0
    printf '%s\xe2\x94\x82%s%s%*s\xe2\x94\x82%s\n' "$on" "$s" "$on" "$pad" "" "$reset"
  }

  hr=$(printf '\xe2\x94\x80%.0s' $(seq 1 $W))
  dot=$(printf '\xe2\x97\x8f')
  arr=$(printf '\xe2\x9d\xaf')

  c_red=$(fgc "${COLORS[2]:-#cc6666}")
  c_grn=$(fgc "${COLORS[3]:-#9ec07c}")
  c_yel=$(fgc "${COLORS[4]:-#e0c06f}")
  c_blu=$(fgc "${COLORS[5]:-#7aa6da}")
  c_mag=$(fgc "${COLORS[6]:-#b294bb}")
  c_cyn=$(fgc "${COLORS[7]:-#8abeb7}")

  printf '%s\xe2\x95\xad%s\xe2\x95\xae%s\n' "$on" "$hr" "$reset"
  row " ${c_red}${dot} ${c_yel}${dot} ${c_grn}${dot}${on}   ${bold}${name}${reset}${on}"
  printf '%s\xe2\x94\x9c%s\xe2\x94\xa4%s\n' "$on" "$hr" "$reset"
  row ""
  row "  ${bold}${c_grn}you${on}@${c_blu}mac ${c_mag}~/code${reset}${on}"
  row "  ${bold}${c_cyn}${arr}${on} git status${reset}${on}"
  row "  On branch ${bold}${c_grn}main${reset}${on}"
  row "  ${c_red}modified:${on}  ${bold}preview.sh${reset}${on}"
  row "  ${c_grn}new file:${on}  ${bold}theme.rb${reset}${on}"
  row "  ${c_yel}untracked:${on}  ${bold}notes.md${reset}${on}"
  row ""
  printf '%s\xe2\x95\xb0%s\xe2\x95\xaf%s\n' "$on" "$hr" "$reset"

  swatch_row() {
    local label="$1" start="$2" end="$3" i hex row c
    for ((row = 0; row < SWATCH_H; row++)); do
      if ((row == 0)); then
        printf '  %-8s' "$label"
      else
        printf '  %8s' ''
      fi
      for i in $(seq "$start" "$end"); do
        hex=${COLORS[$i]:-}
        [ -z "$hex" ] && hex="$bg"
        printf '\e[48;2;%sm' "$(rgb "$hex")"
        for ((c = 0; c < SWATCH_W; c++)); do
          printf ' '
        done
        printf '%s' "$reset"
      done
      printf '\n'
    done
  }

  printf '\n'
  swatch_row "normal" 1 8
  swatch_row "bright" 9 16
  printf '\n  '
  printf '\e[48;2;%sm   \e[0m bg %s   ' "$bgseq" "$bg"
  printf '\e[48;2;%sm   \e[0m fg %s' "$fgseq" "$fg"
  [ -n "$cursor" ] && printf '   \e[48;2;%sm   \e[0m cursor %s' "$(rgb "$cursor")" "$cursor"
  printf '\n'
}

dim=$'\e[2m'
bold=$'\e[1m'
desc_header="${bold}Colorscheme${reset}${dim}"
desc_lines=(
  "${desc_header} browse Gogh terminal colour themes with a live preview"
  "Scroll the list below to explore · Enter to apply · Esc to cancel"
  "Your terminal is not repainted until you confirm a selection"
)

for line in "${desc_lines[@]}"; do
  print_centered "${dim}${line}${reset}"
done
printf '\n'

lines=()
while IFS= read -r line || [[ -n "$line" ]]; do
  lines+=("$line")
done < <(_render_preview)

desc_rows=$((${#desc_lines[@]} + 1))
remaining=$((pane_lines - desc_rows))
top=$(((remaining - ${#lines[@]}) / 2))
((top < 0)) && top=0
for ((i = 0; i < top; i++)); do
  printf '\n'
done

for line in "${lines[@]}"; do
  print_centered "$line"
done
