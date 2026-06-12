#!/usr/bin/env bats

load test_helper

@test "apply_persisted skips when TERMINAL is not wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
echo should-not-run >&2
exit 1
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=kitty \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *should-not-run* ]]
}

@test "apply_persisted runs saved theme when TERMINAL is wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
touch "${GOGH_APPLY_MARKER}"
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  GOGH_APPLY_MARKER="$TEST_HOME/gogh-applied"
  rm -f "$GOGH_APPLY_MARKER"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    GOGH_APPLY_PERSISTED_FORCE=1 GOGH_APPLY_MARKER="$GOGH_APPLY_MARKER" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
  [ -f "$GOGH_APPLY_MARKER" ]
}

@test "apply_persisted writes theme output to a tmux pane tty" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#112233\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/fake-pane-tty"
  : >"$pane_tty"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  grep -q $'\033]11;#112233\007' "$pane_tty"
}

@test "apply_persisted pane tty path works with real Gogh theme structure" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=3024-day.sh
EOF
  cat >"$TEST_HOME/gogh/apply-colors.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;%s\007' "${BACKGROUND_COLOR}"
EOF
  chmod +x "$TEST_HOME/gogh/apply-colors.sh"
  cat >"$TEST_HOME/gogh/installs/3024-day.sh" <<'EOF'
#!/usr/bin/env bash
export BACKGROUND_COLOR="#F7F7F7"
apply_theme() { bash "${PARENT_PATH}/apply-colors.sh"; }
PARENT_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
if [ -z "${GOGH_NONINTERACTIVE+no}" ]; then
  apply_theme
else
  apply_theme 1>/dev/null
fi
EOF
  chmod +x "$TEST_HOME/gogh/installs/3024-day.sh"
  pane_tty="$TEST_HOME/fake-pane-tty-gogh"
  : >"$pane_tty"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  grep -q $'\033]11;#F7F7F7\007' "$pane_tty"
}

@test "apply_persisted hook applies when session TERMINAL is wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=wezterm
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf 'applied'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/fake-pane-tty2"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf 'testsess\n'
    ;;
  show-environment)
    if [ "${2:-}" = "-t" ] && [ "${4:-}" = "-s" ] && [ "${5:-}" = "TERMINAL" ]; then
      printf 'TERMINAL=wezterm\n'
    fi
    ;;
  list-clients)
    printf '424242\n'
    ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "424242" ]; then
  printf 'wezterm\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  [ "$(cat "$pane_tty")" = "applied" ]
}

@test "apply_persisted hook skips when client host is kitty despite state wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=wezterm
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf 'applied'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/fake-pane-kitty-host"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf '88888\n'
    ;;
  list-clients)
    printf '88888\n'
    ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "88888" ]; then
  printf 'kitty\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  [ ! -s "$pane_tty" ]
}

@test "apply_persisted is a no-op without saved state" {
  run env HOME="$TEST_HOME" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
}

@test "apply_persisted --session writes to every pane in tmux session" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#aabbcc\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_a="$TEST_HOME/pane-a"
  pane_b="$TEST_HOME/pane-b"
  : >"$pane_a"
  : >"$pane_b"
  cat >"$TEST_HOME/bin/tmux" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$pane_a" "$pane_b"
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm TMUX=/tmp/tmux-test \
    PATH="$TEST_HOME/bin:$PATH" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" --session
  [ "$status" -eq 0 ]
  grep -q $'\033]11;#aabbcc\007' "$pane_a"
  grep -q $'\033]11;#aabbcc\007' "$pane_b"
}

@test "apply_persisted --session skips when not inside tmux" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
echo should-not-run >&2
exit 1
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
echo tmux-should-not-run >&2
exit 1
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm TMUX= \
    PATH="$TEST_HOME/bin:$PATH" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" --session
  [ "$status" -eq 0 ]
  [[ "$output" != *should-not-run* ]]
  [[ "$output" != *tmux-should-not-run* ]]
}

@test "apply_persisted --session skips when use-terminal overrides to alacritty" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#aabbcc\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/pane-a"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$pane_tty"
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=alacritty TMUX=/tmp/tmux-test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" --session
  [ "$status" -eq 0 ]
  ! grep -q $'\033]11;#aabbcc\007' "$pane_tty"
}

@test "apply_persisted --session skips when persisted terminal is alacritty (tmux hook)" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=alacritty
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#aabbcc\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/pane-a"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$pane_tty"
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL= TMUX=/tmp/tmux-test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" --session
  [ "$status" -eq 0 ]
  ! grep -q $'\033]11;#aabbcc\007' "$pane_tty"
}

@test "apply_persisted pane hook skips when tmux session TERMINAL is alacritty despite state wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=wezterm
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#aabbcc\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/pane-hook"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf 'testsess\n'
    ;;
  show-environment)
    if [ "${2:-}" = "-t" ] && [ "${3:-}" = "testsess" ] && [ "${4:-}" = "-s" ] && [ "${5:-}" = "TERMINAL" ]; then
      printf 'TERMINAL=alacritty\n'
    fi
    ;;
esac
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL= TMUX=/tmp/tmux-test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  ! grep -q $'\033]11;#aabbcc\007' "$pane_tty"
}

@test "apply_persisted skips when tmux session TERMINAL is corrupted alacritty garbage" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs" "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
terminal=wezterm
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#aabbcc\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/pane-hook2"
  : >"$pane_tty"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf 'testsess\n'
    ;;
  show-environment)
    if [ "${2:-}" = "-t" ] && [ "${3:-}" = "testsess" ] && [ "${4:-}" = "-s" ] && [ "${5:-}" = "TERMINAL" ]; then
      printf 'TERMINAL="alacritty"; export TERMINAL;\n'
    fi
    ;;
esac
EOF
  chmod +x "$TEST_HOME/bin/tmux"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL= TMUX=/tmp/tmux-test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  ! grep -q $'\033]11;#aabbcc\007' "$pane_tty"
}
