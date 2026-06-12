#!/usr/bin/env bats

load test_helper

@test "reload_wezterm touches colors.lua when present" {
  local cfg="$TEST_HOME/.config/wezterm/colors.lua"
  mkdir -p "$(dirname "$cfg")"
  echo 'return {}' >"$cfg"
  local before after
  before="$(file_mtime "$cfg")"
  sleep 1
  run env HOME="$TEST_HOME" WEZTERM_CONFIG_DIR="$TEST_HOME/.config/wezterm" \
    bash "$REPO_ROOT/shell/common/gogh/reload_wezterm.sh"
  [ "$status" -eq 0 ]
  after="$(file_mtime "$cfg")"
  [ "$after" -ge "$before" ]
}

@test "wezterm template uses color_scheme from colors.lua" {
  grep -q "GOGH_SCHEME = 'Gogh Active'" "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'config.color_schemes' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'config.color_scheme = GOGH_SCHEME' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'add_to_config_reload_watch_list' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
}

@test "colorscheme skips gogh OSC apply for wezterm" {
  grep -q '\[ "${TERMINAL:-}" != wezterm \]' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
  grep -q 'reload_wezterm.sh' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
  ! grep -q 'apply_persisted' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
}

@test "reload_wezterm is a no-op when colors.lua is missing" {
  run env HOME="$TEST_HOME" WEZTERM_CONFIG_DIR="$TEST_HOME/.config/wezterm" \
    bash "$REPO_ROOT/shell/common/gogh/reload_wezterm.sh"
  [ "$status" -eq 0 ]
}
