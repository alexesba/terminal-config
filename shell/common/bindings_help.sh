#!/usr/bin/env bash
# Print the key bindings reference (source: bindings.md).
#
#   bindings_help.sh          — markdown to stdout
#   bindings_help.sh markdown — same
set -u

_bindings_help_path() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s/bindings.md\n' "$dir"
}

case "${1:-}" in
  list|markdown|'')
    cat "$(_bindings_help_path)"
    ;;
  path)
    _bindings_help_path
    ;;
  *)
    printf 'Usage: %s [markdown|path]\n' "${BASH_SOURCE[0]##*/}" >&2
    exit 1
    ;;
esac
