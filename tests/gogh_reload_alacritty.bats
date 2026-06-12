#!/usr/bin/env bats

load test_helper

@test "reload_alacritty touches alacritty.toml when present" {
  local cfg="$TEST_HOME/.config/alacritty/alacritty.toml"
  mkdir -p "$(dirname "$cfg")"
  echo 'live_config_reload = true' >"$cfg"
  local before after
  before="$(file_mtime "$cfg")"
  sleep 1
  run env HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
    bash "$REPO_ROOT/shell/common/gogh/reload_alacritty.sh"
  [ "$status" -eq 0 ]
  after="$(file_mtime "$cfg")"
  [ "$after" -ge "$before" ]
}

@test "reload_alacritty is a no-op when config is missing" {
  run env HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
    bash "$REPO_ROOT/shell/common/gogh/reload_alacritty.sh"
  [ "$status" -eq 0 ]
}

@test "reload_alacritty clears tmux pane OSC before touching config" {
  local cfg="$TEST_HOME/.config/alacritty/alacritty.toml"
  mkdir -p "$(dirname "$cfg")" "$TEST_HOME/bin"
  echo 'live_config_reload = true' >"$cfg"
  local pane_tty="$TEST_HOME/pane-a"
  : >"$pane_tty"
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
  run env HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" TMUX=/tmp/tmux-test \
    TEST_PANE_TTY="$pane_tty" PATH="$TEST_HOME/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/shell/common/gogh/reload_alacritty.sh"
  [ "$status" -eq 0 ]
  grep -q $'\033]104\007' "$pane_tty"
  grep -q $'\033]110\007' "$pane_tty"
  grep -q $'\033]111\007' "$pane_tty"
}
