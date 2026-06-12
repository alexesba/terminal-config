#!/usr/bin/env bats

load test_helper

_setup_terminal_bins() {
  mkdir -p "$TEST_HOME/bin" \
    "$TEST_HOME/.config/alacritty" \
    "$TEST_HOME/.config/kitty" \
    "$TEST_HOME/.config/wezterm"
  : >"$TEST_HOME/.config/alacritty/alacritty.toml"
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

@test "use-terminal detect --export prints eval line" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  list-clients) printf '%s\n' "77777" ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "77777" ]; then
  printf 'kitty\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" TMUX=/tmp/test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash -c '
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal detect --export
  '
  [ "$status" -eq 0 ]
  [ "$output" = "export TERMINAL=kitty" ]
}

@test "use-terminal detect sets TERMINAL from tmux client walk" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  cat >"$TEST_HOME/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  list-clients) printf '%s\n' "66666" ;;
  display-message) printf 'testsess\n' ;;
  show-environment)
    if [ "${2:-}" = "-t" ] && [ "${4:-}" = "-s" ]; then
      printf 'TERMINAL=wezterm\n'
    fi
    ;;
esac
EOF
  cat >"$TEST_HOME/bin/ps" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-o" ] && [ "$2" = "comm=" ] && [ "$4" = "66666" ]; then
  printf 'Alacritty\n'
elif [ "$1" = "-o" ] && [ "$2" = "ppid=" ]; then
  printf '1\n'
fi
EOF
  chmod +x "$TEST_HOME/bin/tmux" "$TEST_HOME/bin/ps"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" TMUX=/tmp/test \
    PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash -c '
    source "$DOTFILES_DIR/shell/common/terminal_use.sh"
    use-terminal detect >/dev/null
    printf "%s" "$TERMINAL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "alacritty" ]
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
cat >/dev/null
printf 'kitty'
EOF
  chmod +x "$TEST_HOME/bin/fzf"
  run bash -c '
    set +o pipefail 2>/dev/null || true
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
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/pkill" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat >"$TEST_HOME/bin/killall" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$TEST_HOME/bin/pkill" "$TEST_HOME/bin/killall"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=kitty \
    GOGH_APPLY_MARKER="$marker" \
    PATH="$TEST_HOME/bin:$PATH" \
    bash "$REPO_ROOT/shell/common/gogh/apply_saved.sh"
  [ "$status" -eq 0 ]
  [ -f "$marker" ]
}
