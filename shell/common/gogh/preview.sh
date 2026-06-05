#!/usr/bin/env bash
# Render a live, true-color preview of a Gogh theme for fzf's preview pane.
# It only *reads* the hex values from the theme file; it never sources/applies
# the theme, so scrolling the list will not repaint your real terminal.
#
# Usage: preview.sh /path/to/theme.sh
set -u

file="${1:-}"
[ -f "$file" ] || { printf 'No preview available\n'; exit 0; }

# Extract a "#RRGGBB" value for a given exported variable without executing the file.
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

# "#RRGGBB" -> "R;G;B"
rgb() {
  local h=${1#\#}
  printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

bgseq=$(rgb "$bg")
fgseq=$(rgb "$fg")
on=$'\e['"48;2;${bgseq}m"$'\e['"38;2;${fgseq}m"   # paint theme bg + theme fg
fgc() { printf '\e[38;2;%sm' "$(rgb "$1")"; }     # raw escape: switch fg to a palette color

# fzf sets FZF_PREVIEW_COLUMNS / FZF_PREVIEW_LINES for the preview pane.
pane_cols=${FZF_PREVIEW_COLUMNS:-80}
pane_lines=${FZF_PREVIEW_LINES:-24}

# Scale the mock terminal to the preview pane (top half of a fullscreen fzf).
W=$((pane_cols * 72 / 100 - 2))
((W < 52)) && W=52
((W > 110)) && W=110

# Visible width of a rendered line (strip ANSI escapes).
visible_len() {
  local plain
  plain=$(printf '%s' "$1" | sed $'s/\x1b\\[[0-9;]*m//g')
  printf '%s' "${#plain}"
}

_render_preview() {
  local hr dot arr
  local c_red c_grn c_yel c_blu c_mag c_cyn

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
  row " ${c_red}${dot} ${c_yel}${dot} ${c_grn}${dot}${on}   ${name}"
  printf '%s\xe2\x94\x9c%s\xe2\x94\xa4%s\n' "$on" "$hr" "$reset"
  row "  ${c_grn}you${on}@${c_blu}mac ${c_mag}~/code${on}"
  row "  ${c_cyn}${arr}${on} git status"
  row "  On branch ${c_grn}main${on}"
  row "  ${c_red}modified:${on}  preview.sh"
  row "  ${c_grn}new file:${on}  theme.rb"
  row "  ${c_yel}untracked:${on}  notes.md"
  printf '%s\xe2\x95\xb0%s\xe2\x95\xaf%s\n' "$on" "$hr" "$reset"

  swatch_row() {
    local label="$1" start="$2" end="$3" i hex cellw
    cellw=$(((W - 8) / 8))
    ((cellw < 4)) && cellw=4
    ((cellw > 10)) && cellw=10
    printf '  %-8s' "$label"
    for i in $(seq "$start" "$end"); do
      hex=${COLORS[$i]:-}
      [ -z "$hex" ] && hex="$bg"
      printf '\e[48;2;%sm%*s%s' "$(rgb "$hex")" "$cellw" "" "$reset"
    done
    printf '\n'
  }

  printf '\n'
  swatch_row "normal" 1 8
  swatch_row "bright" 9 16
  printf '\n  '
  printf '\e[48;2;%sm \e[0m bg %s   ' "$bgseq" "$bg"
  printf '\e[48;2;%sm \e[0m fg %s' "$fgseq" "$fg"
  [ -n "$cursor" ] && printf '   \e[48;2;%sm \e[0m cursor %s' "$(rgb "$cursor")" "$cursor"
  printf '\n'
}

lines=()
while IFS= read -r line || [[ -n "$line" ]]; do
  lines+=("$line")
done < <(_render_preview)

top=$(((pane_lines - ${#lines[@]}) / 2))
((top < 0)) && top=0
for ((i = 0; i < top; i++)); do
  printf '\n'
done

for line in "${lines[@]}"; do
  lpad=$(((pane_cols - $(visible_len "$line")) / 2))
  ((lpad < 0)) && lpad=0
  printf '%*s%s\n' "$lpad" "" "$line"
done
