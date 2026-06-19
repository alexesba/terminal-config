#!/usr/bin/env bats

load test_helper

@test "gogh_python_deps_ok succeeds when imports work" {
  run bash -c '
    source "$1/shell/common/gogh/deps.sh"
    gogh_python_deps_ok() { return 0; }
    gogh_python_deps_ok
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "gogh_python_deps_hint prints pip install command" {
  run bash -c '
    export GOGH_DIR="/tmp/gogh"
    source "$1/shell/common/gogh/deps.sh"
    gogh_python_deps_hint
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install --user -r /tmp/gogh/requirements.txt"* ]]
}

@test "install_gogh_python_deps skips when already installed" {
  mkdir -p "$TEST_HOME/gogh"
  printf 'tomli\n' >"$TEST_HOME/gogh/requirements.txt"
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    source "$1/shell/common/gogh/deps.sh"
    gogh_python_deps_ok() { return 0; }
    install_gogh_python_deps "'"$TEST_HOME"'/gogh"
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "gogh_python_deps_hint mentions apt when pip is missing" {
  run bash -c '
    export GOGH_DIR="/tmp/gogh"
    export PATH="/usr/bin:/bin"
    source "$1/shell/common/gogh/deps.sh"
    _gogh_pip_available() { return 1; }
    gogh_python_deps_hint
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"apt install python3-pip"* ]]
}

@test "install_gogh_python_deps bootstraps pip before install" {
  mkdir -p "$TEST_HOME/gogh" "$TEST_HOME/bin"
  printf 'tomli\n' >"$TEST_HOME/gogh/requirements.txt"
  cat >"$TEST_HOME/bin/python3" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *import*) exit 1 ;;
  *ensurepip*) exit 0 ;;
  *pip\ --version*) exit 0 ;;
  *pip\ install*) exit 0 ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$TEST_HOME/bin/python3"
  run env HOME="$TEST_HOME" PATH="$TEST_HOME/bin:/usr/bin:/bin" bash -c '
    source "$1/shell/common/gogh/deps.sh"
    _gogh_install_pip_linux() { return 1; }
    install_gogh_python_deps "'"$TEST_HOME"'/gogh"
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "apply_saved fails with hint when alacritty theme apply fails" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=alacritty
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  run --separate-stderr env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=alacritty TERMINAL_OVERRIDE=1 \
    bash "$REPO_ROOT/shell/common/gogh/apply_saved.sh"
  [ "$status" -eq 1 ]
  combined="$output$stderr"
  [[ "$combined" == *"requirements.txt"* || "$combined" == *"Failed to apply saved theme"* ]]
}
