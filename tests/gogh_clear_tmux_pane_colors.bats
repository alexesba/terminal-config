#!/usr/bin/env bats

load test_helper

@test "clear_tmux_pane_colors writes OSC reset sequences to session panes" {
  local pane_tty="$TEST_HOME/pane-a"
  : >"$pane_tty"
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *list-panes*) printf '%s\n' '%0' ;;
  *display-message*) printf '%s\n' "$TEST_PANE_TTY" ;;
  *select-pane*) exit 0 ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" TMUX=/tmp/tmux-test TEST_PANE_TTY="$pane_tty" \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/clear_tmux_pane_colors.sh" --session
  [ "$status" -eq 0 ]
  grep -q $'\033]104\007' "$pane_tty"
  grep -q $'\033]110\007' "$pane_tty"
  grep -q $'\033]111\007' "$pane_tty"
}

@test "clear_tmux_pane_colors is a no-op outside tmux" {
  run env HOME="$TEST_HOME" TMUX= \
    bash "$REPO_ROOT/shell/common/gogh/clear_tmux_pane_colors.sh" --session
  [ "$status" -eq 0 ]
}

@test "reload_kitty clears tmux pane OSC before signaling kitty" {
  local pane_tty="$TEST_HOME/pane-a"
  : >"$pane_tty"
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *list-panes*) printf '%s\n' '%0' ;;
  *display-message*) printf '%s\n' "$TEST_PANE_TTY" ;;
  *select-pane*) exit 0 ;;
  *) exit 1 ;;
esac
EOF
  cat >"$TEST_HOME/bin/kitty" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat >"$TEST_HOME/bin/pkill" <<'EOF'
#!/usr/bin/env bash
[ "$1" = -USR1 ] && [ "$3" = kitty ] && exit 0
exit 1
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/kitty" "$TEST_HOME/bin/pkill"
  run env HOME="$TEST_HOME" TMUX=/tmp/tmux-test TEST_PANE_TTY="$pane_tty" \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/reload_kitty.sh"
  [ "$status" -eq 0 ]
  grep -q $'\033]104\007' "$pane_tty"
}
