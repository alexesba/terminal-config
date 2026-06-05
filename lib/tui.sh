#!/usr/bin/env bash
# tui.sh — tiny terminal-UI helpers for install.sh: collapse answered questions
# in place, render a pre-flight summary, and show a step progress bar.
#
# Pure-bash + tput. Degrades to plain linear output when stdout is not a TTY
# (CI, pipes) or when NO_TUI is set, so nothing emits raw escape codes there.
#
# Relies on the colour vars (RESET/BOLD/DIM/GREEN/YELLOW) from helpers.sh.

# Enable the fancy in-place redraw only on a capable interactive terminal.
TUI_ENABLED=false
if [ -t 1 ] && [ -t 0 ] && [ -z "${NO_TUI:-}" ] \
   && command -v tput >/dev/null 2>&1 && [ "${TERM:-dumb}" != dumb ]; then
  TUI_ENABLED=true
fi

# Mark the start of a question block (remembers the cursor position).
tui_begin() {
  $TUI_ENABLED && tput sc
  return 0
}

# Collapse the current question block into a single "✓ Label  value" line.
# When the TUI is disabled this just appends the summary line (question text
# printed above is left in place, which is fine for a linear log).
# Usage: tui_collapse <label> <value>
tui_collapse() {
  local label="$1" value="$2"
  if $TUI_ENABLED; then
    tput rc
    tput ed
  fi
  echo -e "  ${GREEN}✓${RESET}  $(printf '%-26s' "$label") ${DIM}${value}${RESET}"
}

# Build a fixed-width ASCII bar like [#####-------------------].
# Usage: tui_bar <current> <total> [width]
tui_bar() {
  local current="$1" total="$2" width="${3:-24}" filled empty
  [ "$total" -le 0 ] && total=1
  filled=$(( current * width / total ))
  (( filled > width )) && filled=$width
  (( filled < 0 )) && filled=0
  empty=$(( width - filled ))
  printf '['
  [ "$filled" -gt 0 ] && printf '%*s' "$filled" '' | tr ' ' '#'
  [ "$empty" -gt 0 ] && printf '%*s' "$empty" '' | tr ' ' '-'
  printf ']'
}

# Print one progress line: "[####----]  42%  3/7  label".
# Usage: tui_progress <current> <total> <label>
tui_progress() {
  local current="$1" total="$2" label="$3" pct bar
  [ "$total" -le 0 ] && total=1
  pct=$(( current * 100 / total ))
  bar="$(tui_bar "$current" "$total")"
  echo -e "  ${BOLD}${bar}${RESET} $(printf '%3d%%' "$pct")  ${DIM}${current}/${total}${RESET}  ${label}"
}

# Begin an install step: show a progress bar for the active step only.
# Usage: tui_step_begin <current> <total> <label>
tui_step_begin() {
  if $TUI_ENABLED; then
    tui_progress "$@"
  else
    echo -e "  ${DIM}[$1/$2]${RESET}  $3"
  fi
}

# Finish an install step: replace the progress bar line with a checkmark summary
# while keeping any step output printed below it.
# Usage: tui_step_end <current> <total> <label> <output_lines> [failed]
tui_step_end() {
  local current="$1" total="$2" label="$3" lines="${4:-0}" failed="${5:-0}"
  local mark="${GREEN}✓${RESET}"

  [[ "$failed" -ne 0 ]] && mark="${YELLOW}⚠${RESET}"

  if $TUI_ENABLED; then
    # Cursor sits after the last output line; walk up past output + the bar line.
    if (( lines > 0 )); then
      tput cuu "$lines" || true
    fi
    tput cuu 1 || true
    tput el || true
    echo -e "  ${mark}  ${DIM}${current}/${total}${RESET}  ${label}"
    # Return cursor to the end so the next step starts below prior output.
    if (( lines > 0 )); then
      tput cud "$lines" || true
    fi
  else
    echo -e "  ${mark}  ${DIM}${current}/${total}${RESET}  ${label}"
  fi
}
