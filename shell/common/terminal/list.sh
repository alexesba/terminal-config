#!/usr/bin/env bash
# Rows and fzf formatting for the use-terminal picker.
#
#   terminal_list.sh header <current> <default>
#   terminal_list.sh rows <current> <default>     # id|display|status|config
#   terminal_list.sh fzf-pipe <current> <default>   # title + colored rows
set -u

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi
# shellcheck source=../../lib/helpers.sh disable=SC1091
source "$DOTFILES_DIR/lib/helpers.sh"

_TERMINAL_SHIPPED=(alacritty kitty wezterm)

# True when stdout is a color-capable TTY (or _TERMINAL_COLOR_FORCE is set).
_terminal_use_color() {
  [ -n "${_TERMINAL_COLOR_FORCE:-}" ] && return 0
  [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]
}

# Emit an ANSI sequence when color is enabled.
_terminal_c() {
  _terminal_use_color || return 0
  printf '%b' "${1:-}"
}

# Reset ANSI attributes when color is enabled.
_terminal_c_reset() { _terminal_c "${RESET:-\033[0m}"; }

# Wrap $2 in ANSI color $1 when supported.
_terminal_colored() {
  local code="$1" text="$2"
  if _terminal_use_color; then
    _terminal_c "$code"
    printf '%s' "$text"
    _terminal_c_reset
  else
    printf '%s' "$text"
  fi
}

# Print $3 left-padded/truncated to width $1, optionally with color $2.
_terminal_cell() {
  local width=$1 code="$2" text="$3" pad
  pad=$((width - ${#text}))
  (( pad < 0 )) && pad=0
  if [ -n "$code" ]; then
    _terminal_colored "$code" "$text"
  else
    printf '%s' "$text"
  fi
  printf '%*s' "$pad" ''
}

# Repeat character $1 count $2 times.
_terminal_repeat() {
  local char="$1" count="$2" i out=""
  for ((i = 0; i < count; i++)); do out+="$char"; done
  printf '%s' "$out"
}

# Config path for emulator id $1.
_terminal_config_path() {
  terminal_emulator_config_path "$1"
}

# Human-readable name for emulator id $1.
_terminal_display_name() {
  case "$1" in
    alacritty) printf 'Alacritty' ;;
    kitty)     printf 'Kitty' ;;
    wezterm)   printf 'WezTerm' ;;
    *)         printf '%s' "$1" ;;
  esac
}

# Shorten $HOME/ prefix to ~/ for display.
_terminal_short_path() {
  local p="$1"
  case "$p" in
    "$HOME"/*) printf '~/%s' "${p#$HOME/}" ;;
    *)         printf '%s' "$p" ;;
  esac
}

# True when emulator $1 is available for the picker.
_terminal_installed_p() {
  terminal_emulator_installed_p "$1"
}

# Status column for picker row: active, default, no config, etc.
_terminal_status_label() {
  local term="$1" current="$2" default="$3" cfg
  cfg="$(_terminal_config_path "$term")"
  if [ "$term" = wezterm ]; then
    wezterm_config_present_p || { printf 'no config'; return 0; }
  elif [ ! -f "$cfg" ]; then
    printf 'no config'
    return 0
  fi
  if [ "$term" = "$current" ] && [ "$term" = "$default" ]; then
    printf 'active, default'
  elif [ "$term" = "$current" ]; then
    printf 'active'
  elif [ "$term" = "$default" ]; then
    printf 'default'
  else
    printf 'installed'
  fi
}

# TSV rows id|display|status|config for installed emulators only.
_terminal_rows_tsv() {
  local current="${1:-}" default="${2:-}" term display status cfg
  for term in "${_TERMINAL_SHIPPED[@]}"; do
    _terminal_installed_p "$term" || continue
    display="$(_terminal_display_name "$term")"
    status="$(_terminal_status_label "$term" "$current" "$default")"
    cfg="$(_terminal_config_path "$term")"
    cfg="$(_terminal_short_path "$cfg")"
    printf '%s|%s|%s|%s\n' "$term" "$display" "$status" "$cfg"
  done
}

# Set _TERMINAL_W_* column widths from TSV $1.
_terminal_row_widths() {
  local lines="$1" w_term=8 w_stat=8 w_cfg=6
  local term display status cfg
  while IFS='|' read -r term display status cfg; do
    [ -n "$term" ] || continue
    (( ${#display} > w_term )) && w_term=${#display}
    (( ${#status} > w_stat )) && w_stat=${#status}
    (( ${#cfg} > w_cfg )) && w_cfg=${#cfg}
  done <<EOF
$lines
EOF
  _TERMINAL_W_TERM=$w_term
  _TERMINAL_W_STAT=$w_stat
  _TERMINAL_W_CFG=$w_cfg
}

# One aligned, optionally colored fzf column field.
_terminal_fzf_field() {
  local width=$1 code="$2" text="$3" prefix="${4:-}"
  _terminal_cell "$width" "$code" "${prefix}${text}"
}

# Column header line for fzf table layout.
_terminal_fzf_title_line() {
  local bold_cyan="${BOLD:-\033[1m}${CYAN:-\033[1;36m}" dim="${DIM:-\033[2m}"
  printf '  '
  _terminal_fzf_field "$_TERMINAL_W_TERM" "$bold_cyan" "Terminal"
  printf '  '
  _terminal_fzf_field "$_TERMINAL_W_STAT" "$bold_cyan" "Status"
  printf '  '
  _terminal_fzf_field "$_TERMINAL_W_CFG" "$bold_cyan" "Config"
  printf '\n'
}

# Format TSV rows as tab-separated fzf lines (● marks current terminal).
_terminal_fzf_format_lines() {
  local lines="$1" current="$2" default="$3"
  local term display status cfg prefix green="${GREEN:-\033[1;32m}" dim="${DIM:-\033[2m}"
  local col1 col2 col3
  while IFS='|' read -r term display status cfg; do
    [ -n "$term" ] || continue
    prefix='  '
    col1="$(_terminal_fzf_field "$_TERMINAL_W_TERM" "" "$display" "$prefix")"
    if [ "$term" = "$current" ]; then
      col1="$(_terminal_fzf_field "$_TERMINAL_W_TERM" "$green" "$display" '● ')"
    fi
    col2="$(_terminal_fzf_field "$_TERMINAL_W_STAT" "$dim" "$status")"
    col3="$(_terminal_fzf_field "$_TERMINAL_W_CFG" "$dim" "$cfg")"
    printf '%s\t%s\t%s\t%s\n' "$col1" "$col2" "$col3" "$term"
  done <<EOF
$lines
EOF
}

# "Reset to default" row when session override is active.
_terminal_fzf_reset_line() {
  local default="$1" label col1 col2 dim="${DIM:-\033[2m}"
  label="Reset to default (${default})"
  col1="$(_terminal_fzf_field "$_TERMINAL_W_TERM" "$dim" "$label" '↩ ')"
  col2="$(_terminal_fzf_field "$_TERMINAL_W_STAT" "$dim" "default")"
  printf '%s\t%s\t\treset\n' "$col1" "$col2"
}

# Full fzf input: title, optional reset row, formatted terminal rows.
_terminal_fzf_pipe() {
  local current="${1:-}" default="${2:-}" lines
  lines="$(_terminal_rows_tsv "$current" "$default")"
  [ -n "$lines" ] || return 1
  _terminal_row_widths "$lines"
  _TERMINAL_COLOR_FORCE=1 _terminal_fzf_title_line
  if [ "${TERMINAL:-$default}" != "$default" ] || [ "${TERMINAL_OVERRIDE:-}" = 1 ]; then
    _TERMINAL_COLOR_FORCE=1 _terminal_fzf_reset_line "$default"
  fi
  _TERMINAL_COLOR_FORCE=1 _terminal_fzf_format_lines "$lines" "$current" "$default"
}

# One-line header: current TERMINAL vs install default.
_terminal_header() {
  local current="${1:-}" default="${2:-}" dim="${DIM:-\033[2m}" reset="${RESET:-\033[0m}"
  current="${current:-$default}"
  default="${default:-wezterm}"
  if _terminal_use_color || [ -n "${_TERMINAL_COLOR_FORCE:-}" ]; then
    # helpers.sh stores DIM/RESET as \033 sequences — use %b so fzf --ansi renders them.
    printf 'Target: %b%s%b  Default: %b%s%b' \
      "$dim" "$current" "$reset" \
      "$dim" "$default" "$reset"
  else
    printf 'Target: %s  Default: %s' "$current" "$default"
  fi
}

case "${1:-}" in
  header)
    _terminal_header "${2:-}" "${3:-}"
    ;;
  rows)
    _terminal_rows_tsv "${2:-}" "${3:-}"
    ;;
  fzf-pipe)
    _terminal_fzf_pipe "${2:-}" "${3:-}"
    ;;
  *)
    printf 'Usage: %s header|rows|fzf-pipe <current> <default>\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
