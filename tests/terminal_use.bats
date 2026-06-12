#!/usr/bin/env bats

load test_helper

_setup_terminal_bins() {
  mkdir -p "$TEST_HOME/bin" "$TEST_HOME/.config/kitty" "$TEST_HOME/.config/wezterm"
  : >"$TEST_HOME/.config/kitty/kitty.conf"
  : >"$TEST_HOME/.config/wezterm/wezterm.lua"
  for bin in alacritty kitty wezterm; do
    printf '#!/usr/bin/env bash\n' >"$TEST_HOME/bin/$bin"
    chmod +x "$TEST_HOME/bin/$bin"
  done
}

@test "terminal_list rows lists only installed terminals" {
  _setup_terminal_bins
  rm -f "$TEST_HOME/bin/alacritty"
  run env HOME="$TEST_HOME" PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/terminal_list.sh" rows wezterm wezterm
  [ "$status" -eq 0 ]
  [[ "$output" == *"kitty|"* ]]
  [[ "$output" == *"wezterm|"* ]]
  [[ "$output" != *"alacritty|"* ]]
}

@test "terminal_list fzf-pipe emits ansi colors when piped" {
  _setup_terminal_bins
  run env HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" \
    bash "$REPO_ROOT/shell/common/terminal_list.sh" fzf-pipe kitty wezterm
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033[1;36m'* ]]
  [[ "$output" == *$'\033[1;32m'* ]]
  [[ "$output" == *"Kitty"* ]]
}

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
  mkdir -p "$TEST_HOME/bin"
  printf '#!/usr/bin/env bash\n' >"$TEST_HOME/bin/alacritty"
  chmod +x "$TEST_HOME/bin/alacritty"
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    export PATH="'"$TEST_HOME/bin:$PATH"'"
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal alacritty
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"Config not found"* ]]
}

@test "use-terminal menu picks terminal via fzf" {
  _setup_terminal_bins
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/fzf" <<'EOF'
#!/usr/bin/env bash
echo kitty
EOF
  chmod +x "$TEST_HOME/bin/fzf"
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_DIR="'"$REPO_ROOT"'"
    export PATH="'"$TEST_HOME/bin:$PATH"'"
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal >/dev/null
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "kitty" ]
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
