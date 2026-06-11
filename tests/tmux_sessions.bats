#!/usr/bin/env bats

load test_helper

_setup_mock_tmux() {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-C" ]]; then
  shift 2
fi
case "$1" in
  list-sessions)
    if [[ "${2:-}" == "-F" ]]; then
      printf 'work|/Users/me/work|1|2\n'
      printf 'api|/Users/me/api|0|1\n'
    fi
    exit 0
    ;;
  switch-client|attach-session) exit 0 ;;
  has-session) exit 1 ;;
  new-session) exit 0 ;;
esac
exit 0
EOF
  chmod +x "$TEST_HOME/bin/tmux"
}

@test "tmux-list prints sessions with attached marker" {
  _setup_mock_tmux
  run env PATH="$TEST_HOME/bin:$PATH" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux-list
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Session"* ]]
  [[ "$output" == *"Status"* ]]
  [[ "$output" == *"attached"* ]]
  [[ "$output" == *"detached"* ]]
  [[ "$output" == *"work"* ]]
  [[ "$output" == *"/Users/me/work"* ]]
  [[ "$output" == *"--------"* ]]
}

@test "tmux-list reports no sessions when tmux list fails" {
  mkdir -p "$TEST_HOME/bin"
  printf '#!/usr/bin/env bash\nexit 1\n' >"$TEST_HOME/bin/tmux"
  chmod +x "$TEST_HOME/bin/tmux"
  run env PATH="$TEST_HOME/bin:$PATH" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux-list
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == "No tmux sessions." ]]
}

@test "tmux_attach_session uses switch-client inside tmux" {
  _setup_mock_tmux
  run env TMUX=/tmp/tmux-123 PATH="$TEST_HOME/bin:$PATH" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux_attach_session work
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "tmux-start creates a session when none exists" {
  _setup_mock_tmux
  mkdir -p "$TEST_HOME/work"
  run env PATH="$TEST_HOME/bin:$PATH" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux-start "$2/work"
  ' _ "$REPO_ROOT" "$TEST_HOME"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No Session found"* ]]
  [[ "$output" == *"Creating"* ]]
}

@test "tmux-switch fails when no sessions exist" {
  mkdir -p "$TEST_HOME/bin"
  printf '#!/usr/bin/env bash\nexit 1\n' >"$TEST_HOME/bin/tmux"
  chmod +x "$TEST_HOME/bin/tmux"
  run env PATH="$TEST_HOME/bin:$PATH" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux-switch
  ' _ "$REPO_ROOT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No tmux sessions."* ]]
}

@test "tmux-switch fails when fzf is missing" {
  _setup_mock_tmux
  run env PATH="$TEST_HOME/bin:/usr/bin:/bin" bash -c '
    source "$1/lib/tmux_sessions.sh"
    tmux-switch
  ' _ "$REPO_ROOT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"fzf not found"* ]]
}
