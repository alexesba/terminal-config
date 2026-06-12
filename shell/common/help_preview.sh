#!/usr/bin/env bash
# fzf --preview helper for help menu rows (action<TAB>hint passed as args).
set -u

action="${1:-}"
hint="${2:-}"

case "$action" in
  edit:*)
    path="${action#edit:}"
    if [ -f "$path" ]; then
      if command -v bat >/dev/null 2>&1; then
        bat --style=numbers --color=always --paging=never --line-range 1:40 "$path" 2>/dev/null \
          || head -40 "$path"
      else
        head -40 "$path"
      fi
    else
      printf '%s\n\n(File not on disk — run ./update.sh or install.sh to copy templates.)\n' "$hint"
    fi
    ;;
  *)
    printf '%s\n' "$hint"
    ;;
esac
