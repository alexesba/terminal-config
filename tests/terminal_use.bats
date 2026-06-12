#!/usr/bin/env bats

load test_helper

@test "use-terminal reset restores TERMINAL from local.sh" {
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    export TERMINAL=kitty
    export TERMINAL_OVERRIDE=1
    use-terminal reset >/dev/null
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "wezterm" ]
}

@test "use-terminal kitty sets session override" {
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  mkdir -p "$TEST_HOME/.config/kitty"
  : >"$TEST_HOME/.config/kitty/kitty.conf"
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal kitty >/dev/null
    printf "%s|%s" "$TERMINAL" "${TERMINAL_OVERRIDE:-}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "kitty|1" ]
}

@test "use-terminal fails when config template is missing" {
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal alacritty
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"Config not found"* ]]
}

@test "apply_saved runs theme for session TERMINAL" {
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
  marker="$TEST_HOME/gogh-applied-kitty"
  rm -f "$marker"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=kitty \
    GOGH_APPLY_MARKER="$marker" \
    bash "$REPO_ROOT/shell/common/gogh/apply_saved.sh"
  [ "$status" -eq 0 ]
  [ -f "$marker" ]
}
