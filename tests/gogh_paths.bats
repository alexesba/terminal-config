#!/usr/bin/env bats

load test_helper

setup_gogh_repo() {
  local root="$TEST_HOME/gogh"
  mkdir -p "$root/installs"
  printf '#!/usr/bin/env bash\n' >"$root/apply-colors.sh"
  chmod +x "$root/apply-colors.sh"
  cat >"$root/installs/demo.sh" <<'EOF'
#!/usr/bin/env bash
export PROFILE_NAME="Demo"
apply_theme() { bash "${GOGH_APPLY_SCRIPT:?missing}"; }
SCRIPT_PATH="${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PARENT_PATH="$(dirname "${SCRIPT_PATH}")"
apply_theme
EOF
  chmod +x "$root/installs/demo.sh"
  printf '%s\n' "$root"
}

@test "gogh_resolve_terminal prefers wezterm when WEZTERM_PANE is set" {
  run env DOTFILES_DIR="$REPO_ROOT" TERMINAL=kitty WEZTERM_PANE=1 bash -c \
    'source "$DOTFILES_DIR/shell/common/gogh/paths.sh"; gogh_resolve_terminal'
  [ "$status" -eq 0 ]
  [ "$output" = "wezterm" ]
}

@test "gogh_repo_root normalizes GOGH_DIR when it points at installs" {
  local root
  root="$(setup_gogh_repo)"
  run env DOTFILES_DIR="$REPO_ROOT" GOGH_DIR="$root/installs" bash -c \
    'source "$DOTFILES_DIR/shell/common/gogh/paths.sh"; gogh_repo_root'
  [ "$status" -eq 0 ]
  [ "$output" = "$root" ]
}

@test "gogh_apply_theme_script exports GOGH_APPLY_SCRIPT" {
  local root
  root="$(setup_gogh_repo)"
  cat >"$root/apply-colors.sh" <<'EOF'
#!/usr/bin/env bash
printf 'apply-colors\n'
EOF
  chmod +x "$root/apply-colors.sh"
  run env DOTFILES_DIR="$REPO_ROOT" GOGH_DIR="$root" bash -c \
    'source "$DOTFILES_DIR/shell/common/gogh/paths.sh"; gogh_apply_theme_script "$(gogh_repo_root)" "$(gogh_installs_dir)/demo.sh" kitty'
  [ "$status" -eq 0 ]
  [ "$output" = "apply-colors" ]
}

@test "wezterm_config_dir uses Windows profile on WSL when unset" {
  mkdir -p "$TEST_HOME/win/.config/wezterm"
  touch "$TEST_HOME/win/.config/wezterm/wezterm.lua"
  run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" WEZTERM_CONFIG_DIR= bash -c '
    source "$REPO_ROOT/lib/helpers.sh"
    is_wsl() { return 0; }
    wsl_windows_home() { printf "%s\n" "'"$TEST_HOME/win"'"; }
    wezterm_config_dir
  '
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_HOME/win/.config/wezterm" ]
}

@test "persist.sh writes colors.lua to wezterm_config_dir on WSL" {
  local theme="$TEST_HOME/theme.sh"
  local win_cfg="$TEST_HOME/win/.config/wezterm"
  mkdir -p "$win_cfg"
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
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" WEZTERM_CONFIG_DIR="$win_cfg" \
    bash "$REPO_ROOT/shell/common/gogh/persist.sh" "$theme" wezterm
  [ "$status" -eq 0 ]
  [ -f "$win_cfg/colors.lua" ]
  grep -q 'scheme_name = "3024 Day"' "$win_cfg/colors.lua"
}
