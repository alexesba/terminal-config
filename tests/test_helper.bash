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

# ps mock for tests that must not detect a hosting emulator via parent walk.
# macOS GUI apps often report comm= '-' and ucomm= 'WezTerm' / 'kitty' — handle both.
mock_ps_no_emulator() {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ]; then
  printf -- '-\n'
elif [ "$1" = "-o" ] && [ "$2" = "ucomm=" ]; then
  printf 'bats\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/ps"
}

# Portable file mtime (GNU stat uses -c; BSD/macOS uses -f).
file_mtime() {
  if stat --version >/dev/null 2>&1; then
    stat -c '%Y' "$1"
  else
    stat -f '%m' "$1"
  fi
}
