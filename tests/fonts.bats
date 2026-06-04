#!/usr/bin/env bats

load test_helper

@test "nerd_font_family returns display name for each id" {
  [ "$(nerd_font_family caskaydia)" = "CaskaydiaCove Nerd Font Propo" ]
  [ "$(nerd_font_family jetbrains)" = "JetBrainsMono Nerd Font" ]
  [ "$(nerd_font_family fira)" = "FiraCode Nerd Font" ]
  [ "$(nerd_font_family hack)" = "Hack Nerd Font Mono" ]
}

@test "nerd_font_id_from_family reverses family to id" {
  [ "$(nerd_font_id_from_family 'CaskaydiaCove Nerd Font Propo')" = "caskaydia" ]
  [ "$(nerd_font_id_from_family 'FiraCode Nerd Font')" = "fira" ]
}

@test "substitute_font_placeholder replaces {{FONT_FAMILY}} in config" {
  local file="$TEST_HOME/wezterm.lua"
  printf '%s\n' "family = '{{FONT_FAMILY}}'," >"$file"

  substitute_font_placeholder "$file" "CaskaydiaCove Nerd Font Propo"

  grep -q "family = 'CaskaydiaCove Nerd Font Propo'," "$file"
  ! grep -q '{{FONT_FAMILY}}' "$file"
}

@test "install_config_from_template substitutes font placeholder on copy" {
  local dest="$TEST_HOME/.config/wezterm/wezterm.lua"

  install_config_from_template "$REPO_ROOT" \
    "terminal-emulators/wezterm.lua.example" "$dest" \
    "JetBrainsMono Nerd Font" >/dev/null

  grep -q "family = 'JetBrainsMono Nerd Font'," "$dest"
  ! grep -q '{{FONT_FAMILY}}' "$dest"
}

@test "custom_export_value reads export from custom.sh without sourcing" {
  local file="$TEST_HOME/custom.sh"
  cat >"$file" <<'EOF'
export TERMINAL="wezterm"
export TERMINAL_FONT="CaskaydiaCove Nerd Font Propo"
export TERMINAL_FONT_ID="caskaydia"
EOF

  [ "$(custom_export_value "$file" TERMINAL)" = "wezterm" ]
  [ "$(custom_export_value "$file" TERMINAL_FONT_ID)" = "caskaydia" ]
}

@test "resolve_nerd_font_id prefers TERMINAL_FONT_ID over TERMINAL_FONT" {
  local file="$TEST_HOME/custom.sh"
  cat >"$file" <<'EOF'
export TERMINAL_FONT="FiraCode Nerd Font"
export TERMINAL_FONT_ID="caskaydia"
EOF

  [ "$(resolve_nerd_font_id "$file")" = "caskaydia" ]
}

@test "resolve_nerd_font_id falls back to TERMINAL_FONT family" {
  local file="$TEST_HOME/custom.sh"
  printf '%s\n' 'export TERMINAL_FONT="Hack Nerd Font Mono"' >"$file"

  [ "$(resolve_nerd_font_id "$file")" = "hack" ]
}
