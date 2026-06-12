#!/usr/bin/env bats

load test_helper

@test "persist.sh writes scheme_name to colors.lua for wezterm" {
  local theme="$TEST_HOME/theme.sh"
  local cfg="$TEST_HOME/.config/wezterm/colors.lua"
  cat >"$theme" <<'EOF'
export PROFILE_NAME="3024 Day"
export BACKGROUND_COLOR="#111111"
export FOREGROUND_COLOR="#eeeeee"
export CURSOR_COLOR="#eeeeee"
export COLOR_01="#111111"
export COLOR_02="#222222"
export COLOR_03="#333333"
export COLOR_04="#444444"
export COLOR_05="#555555"
export COLOR_06="#666666"
export COLOR_07="#777777"
export COLOR_08="#888888"
export COLOR_09="#999999"
export COLOR_10="#aaaaaa"
export COLOR_11="#bbbbbb"
export COLOR_12="#cccccc"
export COLOR_13="#dddddd"
export COLOR_14="#eeeeee"
export COLOR_15="#ffffff"
export COLOR_16="#000000"
EOF
  mkdir -p "$(dirname "$cfg")"
  echo 'return {}' >"$cfg"
  local before after
  before="$(file_mtime "$cfg")"
  sleep 1
  run env HOME="$TEST_HOME" WEZTERM_CONFIG_DIR="$TEST_HOME/.config/wezterm" \
    bash "$REPO_ROOT/shell/common/gogh/persist.sh" "$theme" wezterm
  [ "$status" -eq 0 ]
  grep -q 'scheme_name = "3024 Day"' "$cfg"
  after="$(file_mtime "$cfg")"
  [ "$after" -ge "$before" ]
}

@test "wezterm template uses scheme_name from colors.lua" {
  grep -q 'data.scheme_name' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'config.color_schemes' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'config.color_scheme = scheme_name' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  grep -q 'add_to_config_reload_watch_list' "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
  ! grep -q "GOGH_SCHEME" "$REPO_ROOT/terminal-emulators/wezterm.lua.example"
}

@test "colorscheme skips gogh OSC apply for wezterm" {
  grep -q '\[ "${TERMINAL:-}" != wezterm \]' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
  ! grep -q 'reload_wezterm.sh' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
  ! grep -q 'apply_persisted' "$REPO_ROOT/shell/common/gogh/colorscheme.sh"
}
