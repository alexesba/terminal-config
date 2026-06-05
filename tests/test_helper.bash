# Shared setup for terminal-config bats tests.

setup() {
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
