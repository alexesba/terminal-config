#!/usr/bin/env bash
# Gogh Python dependencies (Alacritty / Terminator apply scripts).
#
#   gogh_python_deps_ok          — exit 0 when imports work
#   install_gogh_python_deps     — pip install --user -r requirements.txt
#   gogh_python_deps_hint        — print install command to stderr
#
# Do not use set -u here — colorscheme sources this file into an interactive shell.

# Return 0 when python3 -m pip or pip3 is usable.
_gogh_pip_available() {
  python3 -m pip --version >/dev/null 2>&1 && return 0
  command -v pip3 >/dev/null 2>&1 && pip3 --version >/dev/null 2>&1
}

# Run pip (python3 -m pip preferred, then pip3).
_gogh_run_pip() {
  if python3 -m pip "$@"; then
    return 0
  fi
  if command -v pip3 >/dev/null 2>&1; then
    pip3 "$@"
    return $?
  fi
  return 1
}

# Install python3-pip via the system package manager (Linux only).
_gogh_install_pip_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    printf 'Installing python3-pip via apt…\n' >&2
    sudo apt-get install -y python3-pip
    return $?
  fi
  if command -v dnf >/dev/null 2>&1; then
    printf 'Installing python3-pip via dnf…\n' >&2
    sudo dnf install -y python3-pip
    return $?
  fi
  if command -v pacman >/dev/null 2>&1; then
    printf 'Installing python-pip via pacman…\n' >&2
    sudo pacman -S --noconfirm python-pip
    return $?
  fi
  return 1
}

# Ensure pip exists: ensurepip, then Linux package manager when needed.
_gogh_bootstrap_pip() {
  _gogh_pip_available && return 0

  if python3 -m ensurepip --user --default-pip >/dev/null 2>&1 \
    || python3 -m ensurepip --user >/dev/null 2>&1 \
    || python3 -m ensurepip >/dev/null 2>&1; then
    _gogh_pip_available && return 0
  fi

  if [[ "$(uname -s 2>/dev/null)" == Linux ]]; then
    _gogh_install_pip_linux && _gogh_pip_available && return 0
  fi

  return 1
}

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
  if ! _gogh_pip_available; then
    printf 'python3 pip is missing — install it first, e.g.: sudo apt install python3-pip\n' >&2
  fi
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

  if ! _gogh_bootstrap_pip; then
    printf 'Could not bootstrap pip for python3.\n' >&2
    return 1
  fi

  _gogh_run_pip install --user -r "$req"
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
