# Shared setup for terminal-config bats tests.

bats_require_minimum_version 1.5.0

setup() {
  export TERMINAL_AUTO_DETECT=0
  export TEST_HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$TEST_HOME"
  export HOME="$TEST_HOME"
  export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  # shellcheck source=../lib/helpers.sh disable=SC1091
  source "$REPO_ROOT/lib/helpers.sh"
  # shellcheck source=../lib/fonts.sh disable=SC1091
  source "$REPO_ROOT/lib/fonts.sh"
  # shellcheck source=../lib/tui.sh disable=SC1091
  source "$REPO_ROOT/lib/tui.sh"
}

# Portable file mtime (GNU stat uses -c; BSD/macOS uses -f).
file_mtime() {
  if stat --version >/dev/null 2>&1; then
    stat -c '%Y' "$1"
  else
    stat -f '%m' "$1"
  fi
}
