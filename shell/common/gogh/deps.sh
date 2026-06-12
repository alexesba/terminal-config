#!/usr/bin/env bash
# Gogh Python dependencies (Alacritty / Terminator apply scripts).
#
#   gogh_python_deps_ok          — exit 0 when imports work
#   install_gogh_python_deps     — pip install --user -r requirements.txt
#   gogh_python_deps_hint        — print install command to stderr
#
# Do not use set -u here — colorscheme sources this file into an interactive shell.

# Return 0 when Gogh's Python imports are available for Alacritty theming.
gogh_python_deps_ok() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 -c "import tomli, tomli_w; import ruamel.yaml" 2>/dev/null
}

# Gogh repo root for requirements.txt lookup.
gogh_dir_for_deps() {
  printf '%s\n' "${GOGH_DIR:-$HOME/src/gogh}"
}

# Print pip install hint to stderr.
gogh_python_deps_hint() {
  local gogh_dir
  gogh_dir="$(gogh_dir_for_deps)"
  printf 'Alacritty theming needs Gogh Python deps: pip install --user -r %s/requirements.txt\n' "$gogh_dir" >&2
}

# pip install --user Gogh requirements when imports are missing.
install_gogh_python_deps() {
  local gogh_dir req
  gogh_dir="${1:-$(gogh_dir_for_deps)}"
  req="$gogh_dir/requirements.txt"

  if gogh_python_deps_ok; then
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 not found — cannot install Gogh Python dependencies.\n' >&2
    return 1
  fi
  if [ ! -f "$req" ]; then
    printf 'Gogh requirements not found at %s\n' "$req" >&2
    return 1
  fi

  python3 -m pip install --user -r "$req"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    ensure)
      if gogh_python_deps_ok; then
        exit 0
      fi
      install_gogh_python_deps
      ;;
    hint)
      gogh_python_deps_hint
      ;;
    *)
      printf 'Usage: %s ensure|hint\n' "${0##*/}" >&2
      exit 1
      ;;
  esac
fi
