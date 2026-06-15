#!/usr/bin/env bash
# fzf --preview helper for help menu rows (action<TAB>hint passed as args).
set -u

action="${1:-}"
hint="${2:-}"

case "$action" in
  edit:*)
    bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config_preview.sh" \
      "${action#edit:}" "$hint"
    ;;
  *)
    printf '%s\n' "$hint"
    ;;
esac
