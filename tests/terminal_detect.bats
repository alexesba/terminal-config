#!/usr/bin/env bats

load test_helper

# Env-based detection tests use env -i so local TMUX / parent process chains
# (Kitty, WezTerm, etc.) do not override the vars under test — CI is already clean.

@test "detect_terminal_emulator reads KITTY_WINDOW_ID" {
  run env -i HOME="$TEST_HOME" PATH="/usr/bin:/bin" KITTY_WINDOW_ID=1 \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "kitty" ]
}

@test "detect_terminal_emulator reads WEZTERM_PANE" {
  run env -i HOME="$TEST_HOME" PATH="/usr/bin:/bin" WEZTERM_PANE=0 \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "wezterm" ]
}

@test "detect_terminal_emulator reads ALACRITTY_SOCKET" {
  run env -i HOME="$TEST_HOME" PATH="/usr/bin:/bin" ALACRITTY_SOCKET=/tmp/alacritty \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
}

@test "detect_terminal_emulator returns failure when unknown" {
  mock_ps_no_emulator
  run env -i HOME="$TEST_HOME" PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 1 ]
}

@test "detect_terminal_emulator prefers tmux client host over stale session TERMINAL" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  show-environment)
    [ "${2:-}" = "-s" ] && printf '%s\n' "TERMINAL=wezterm"
    ;;
  list-clients)
    printf '%s\n' "99999"
    ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "99999" ]; then
  printf 'Alacritty\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env TMUX=/tmp/test PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
}

@test "detect_terminal_emulator prefers tmux path before WEZTERM env vars" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf '88888\n'
    ;;
  list-clients)
    printf '%s\n' "88888"
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
  run env TMUX=/tmp/test WEZTERM_PANE=0 PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "kitty" ]
}

@test "detect_terminal_emulator sanitizes corrupted tmux session TERMINAL" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf '\n'
    ;;
  show-environment)
    [ "${2:-}" = "-s" ] && printf '%s\n' 'TERMINAL="alacritty"; export TERMINAL;'
    ;;
esac
EOF
  mock_ps_no_emulator
  chmod +x "$TEST_HOME/bin/tmux"
  # env -i + ps mock: reach session TERMINAL fallback, not hosting emulator env/parent walk.
  run env -i HOME="$TEST_HOME" PATH="$TEST_HOME/bin:/usr/bin:/bin" TMUX=/tmp/test \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
}

@test "detect_terminal_emulator prefers client walk over stale session wezterm" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  display-message)
    printf '55555\n'
    ;;
  list-clients)
    printf '55555\n'
    ;;
  show-environment)
    [ "${2:-}" = "-s" ] && printf '%s\n' 'TERMINAL=wezterm'
    ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "55555" ]; then
  printf 'Alacritty\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env TMUX=/tmp/test PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/terminal_detect.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
}

@test "sync_terminal_to_host sets TERMINAL from env when config exists" {
  mkdir -p "$TEST_HOME/.config/kitty"
  : >"$TEST_HOME/.config/kitty/kitty.conf"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    export TERMINAL_AUTO_DETECT=1
    export KITTY_WINDOW_ID=1
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    sync_terminal_to_host
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "kitty" ]
}

@test "sync_terminal_to_host works without emulator binary on PATH" {
  mkdir -p "$TEST_HOME/.config/alacritty"
  : >"$TEST_HOME/.config/alacritty/alacritty.toml"
  run env -i HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" PATH="/usr/bin:/bin" \
    TERM=dumb TERMINAL_AUTO_DETECT=1 TERMINAL=wezterm ALACRITTY_SOCKET=/tmp/alacritty.sock \
    bash -c '
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    sync_terminal_to_host
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
}

@test "sync_terminal_to_host sets TERMINAL without config file on disk" {
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    export TERMINAL_AUTO_DETECT=1
    export KITTY_WINDOW_ID=1
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    sync_terminal_to_host
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "kitty" ]
}

@test "sync_terminal_to_host skips when TERMINAL_OVERRIDE is set" {
  mkdir -p "$TEST_HOME/.config/kitty"
  : >"$TEST_HOME/.config/kitty/kitty.conf"
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    export TERMINAL_AUTO_DETECT=1
    export TERMINAL=wezterm
    export TERMINAL_OVERRIDE=1
    export KITTY_WINDOW_ID=1
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    sync_terminal_to_host
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "wezterm" ]
}
