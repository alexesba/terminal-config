#!/usr/bin/env bats

load test_helper

@test "gogh current.sh reads state file" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh"
  cat >"$gogh/nord.sh" <<'EOF'
export PROFILE_NAME="Nord"
EOF
  mkdir -p "$TEST_HOME/.local/state/gogh"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Nord
file=nord.sh
EOF
  run env -u TERMINAL HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    WEZTERM_CONFIG_DIR= KITTY_CONFIG_DIRECTORY= GOGH_STATE_FILE= \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh"
  [ "$status" -eq 0 ]
  [ "$output" = $'Nord\tnord.sh' ]
}

@test "gogh current.sh reads per-terminal JSON for hosting emulator" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh" "$TEST_HOME/.local/state/gogh"
  cat >"$gogh/mono-yellow.sh" <<'EOF'
export PROFILE_NAME="Mono Yellow"
EOF
  cat >"$gogh/acid-green.sh" <<'EOF'
export PROFILE_NAME="Acid Green"
EOF
  cat >"$TEST_HOME/.local/state/gogh/alacritty" <<'EOF'
name=Acid Green
file=acid-green.sh
EOF
  cat >"$TEST_HOME/.local/state/gogh/kitty" <<'EOF'
name=Mono Yellow
file=mono-yellow.sh
EOF
  cat >"$TEST_HOME/.local/state/gogh/wezterm" <<'EOF'
name=3024 Day
file=3024-day.sh
EOF
  printf 'kitty\n' >"$TEST_HOME/.local/state/gogh/last_active"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=alacritty \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" alacritty
  [ "$status" -eq 0 ]
  [ "$output" = $'Acid Green\tacid-green.sh' ]

  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=kitty \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" kitty
  [ "$status" -eq 0 ]
  [ "$output" = $'Mono Yellow\tmono-yellow.sh' ]
}

@test "gogh current.sh reads wezterm colors.lua when no JSON entry" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh" "$TEST_HOME/.config/wezterm"
  cat >"$gogh/clone-of-ubuntu.sh" <<'EOF'
export PROFILE_NAME="Clone Of Ubuntu"
EOF
  cat >"$TEST_HOME/.config/wezterm/colors.lua" <<'EOF'
-- Source theme: clone-of-ubuntu.sh
return {
  scheme_name = "Clone Of Ubuntu",
}
EOF
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    WEZTERM_CONFIG_DIR="$TEST_HOME/.config/wezterm" KITTY_CONFIG_DIRECTORY= GOGH_STATE_FILE= \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" wezterm
  [ "$status" -eq 0 ]
  [ "$output" = $'Clone Of Ubuntu\tclone-of-ubuntu.sh' ]
}

@test "gogh current.sh reads kitty colors.conf theme name" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh" "$TEST_HOME/.config/kitty"
  cat >"$gogh/nord.sh" <<'EOF'
export PROFILE_NAME="Nord"
EOF
  cat >"$TEST_HOME/.config/kitty/colors.conf" <<'EOF'
# Color theme: Nord
background #2E3440
EOF
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    WEZTERM_CONFIG_DIR= KITTY_CONFIG_DIRECTORY="$TEST_HOME/.config/kitty" GOGH_STATE_FILE= \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" kitty
  [ "$status" -eq 0 ]
  [ "$output" = $'Nord\tnord.sh' ]
}

@test "gogh state migrates legacy flat current into per-terminal files" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh" "$TEST_HOME/.local/state/gogh"
  cat >"$gogh/nord.sh" <<'EOF'
export PROFILE_NAME="Nord"
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Nord
file=nord.sh
terminal=kitty
EOF
  run env -u TERMINAL HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" kitty
  [ "$status" -eq 0 ]
  [ "$output" = $'Nord\tnord.sh' ]
  [ -f "$TEST_HOME/.local/state/gogh/kitty" ]
  [ ! -f "$TEST_HOME/.local/state/gogh/current" ]
  [ -f "$TEST_HOME/.local/state/gogh/current.migrated" ]
}

@test "gogh state migrates JSON current into per-terminal files" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh" "$TEST_HOME/.local/state/gogh"
  cat >"$gogh/acid-green.sh" <<'EOF'
export PROFILE_NAME="Acid Green"
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
{
  "alacritty": {
    "file": "acid-green.sh",
    "name": "Acid Green"
  },
  "kitty": {},
  "last_active": "alacritty",
  "wezterm": {}
}
EOF
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    bash "$REPO_ROOT/shell/common/gogh/current.sh" "$gogh" alacritty
  [ "$status" -eq 0 ]
  [ "$output" = $'Acid Green\tacid-green.sh' ]
  [ -f "$TEST_HOME/.local/state/gogh/alacritty" ]
  [ ! -f "$TEST_HOME/.local/state/gogh/current" ]
}

@test "gogh list.sh colorizes the active theme header" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh"
  cat >"$gogh/nord.sh" <<'EOF'
export PROFILE_NAME="Nord"
export BACKGROUND_COLOR="#2E3440"
export FOREGROUND_COLOR="#D8DEE9"
EOF
  run bash "$REPO_ROOT/shell/common/gogh/list.sh" header "$gogh/nord.sh" Nord
  [ "$status" -eq 0 ]
  [[ "$output" == *'Active theme:'* ]]
  [[ "$output" == *'Nord'* ]]
  [[ "$output" == *$'\e[48;2;'* ]]
}

@test "gogh list.sh marks the active theme row" {
  local gogh="$TEST_HOME/gogh/installs"
  mkdir -p "$gogh"
  run bash "$REPO_ROOT/shell/common/gogh/list.sh" "$gogh" nord.sh Nord <<'EOF'
Acid	acid.sh
Nord	nord.sh
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *'● Nord'* ]]
  [[ "$output" == *'  Acid'* ]]
}

@test "persist.sh records current theme state" {
  local theme="$TEST_HOME/theme.sh"
  cat >"$theme" <<'EOF'
export PROFILE_NAME="Test Theme"
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
  run env HOME="$TEST_HOME" bash "$REPO_ROOT/shell/common/gogh/persist.sh" "$theme" kitty
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.local/state/gogh/kitty" ]
  grep -q '^name=Test Theme$' "$TEST_HOME/.local/state/gogh/kitty"
  grep -q '^file=theme.sh$' "$TEST_HOME/.local/state/gogh/kitty"
  [ "$(cat "$TEST_HOME/.local/state/gogh/last_active")" = "kitty" ]
}
