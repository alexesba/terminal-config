#!/usr/bin/env bats

load test_helper

@test "nerd_font_family returns terminal family name for each id" {
  [ "$(nerd_font_family caskaydia)" = "CaskaydiaCove NFP" ]
  [ "$(nerd_font_family jetbrains)" = "JetBrainsMono NFM" ]
  [ "$(nerd_font_family fira)" = "FiraCode Nerd Font Mono" ]
  [ "$(nerd_font_family hack)" = "Hack Nerd Font Mono" ]
}

@test "nerd_font_family_for_terminal picks ui name for alacritty and wezterm on macOS" {
  run env OSTYPE=darwin bash -c '
    source "$1/lib/fonts.sh"
    nerd_font_family_for_terminal caskaydia alacritty
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ "$output" = "CaskaydiaCove Nerd Font Propo" ]
  [ "$(OSTYPE=darwin bash -c "source $REPO_ROOT/lib/fonts.sh; nerd_font_family_for_terminal caskaydia kitty")" = "CaskaydiaCove NFP" ]
}

@test "nerd_font_family_for_terminal uses linux mono fallback without fc-match" {
  run env OSTYPE=linux-gnu bash -c '
    source "$1/lib/fonts.sh"
    nerd_font_fc_resolve() { return 1; }
    nerd_font_family_for_terminal caskaydia kitty
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ "$output" = "CaskaydiaCove NFM" ]
  run env OSTYPE=linux-gnu bash -c '
    source "$1/lib/fonts.sh"
    nerd_font_fc_resolve() { return 1; }
    nerd_font_family_for_terminal caskaydia alacritty
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ "$output" = "CaskaydiaCove Nerd Font Mono" ]
}

@test "nerd_font_id_from_family reverses family to id" {
  [ "$(nerd_font_id_from_family 'CaskaydiaCove NFP')" = "caskaydia" ]
  [ "$(nerd_font_id_from_family 'CaskaydiaCove Nerd Font Propo')" = "caskaydia" ]
  [ "$(nerd_font_id_from_family 'FiraCode Nerd Font')" = "fira" ]
}

@test "substitute_font_placeholder replaces {{FONT_FAMILY}} in config" {
  local file="$TEST_HOME/wezterm.lua"
  printf '%s\n' "family = '{{FONT_FAMILY}}'," >"$file"

  substitute_font_placeholder "$file" "CaskaydiaCove NFP"

  grep -q "family = 'CaskaydiaCove NFP'," "$file"
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

@test "custom_export_value reads export from a local config file without sourcing" {
  local file="$TEST_HOME/.local.sh"
  cat >"$file" <<'EOF'
export TERMINAL="wezterm"
export TERMINAL_FONT="CaskaydiaCove NFP"
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

@test "nerd_font_installed_p detects files in ~/.local/share/fonts" {
  mkdir -p "$TEST_HOME/.local/share/fonts"
  : >"$TEST_HOME/.local/share/fonts/CaskaydiaCoveNerdFont-Regular.ttf"
  run env HOME="$TEST_HOME" bash -c '
    source "$1/lib/fonts.sh"
    nerd_font_installed_p caskaydia
  ' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "update_terminal_font_config writes kitty font_family" {
  mkdir -p "$TEST_HOME/.config/kitty"
  printf 'font_family monospace\n' >"$TEST_HOME/.config/kitty/kitty.conf"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" OSTYPE=linux-gnu bash -c '
    source "$DOTFILES_DIR/lib/helpers.sh"
    source "$DOTFILES_DIR/lib/fonts.sh"
    nerd_font_fc_resolve() { return 1; }
    update_terminal_font_config kitty "$(nerd_font_family_for_terminal caskaydia kitty)"
  '
  [ "$status" -eq 0 ]
  grep -q '^font_family CaskaydiaCove NFM$' "$TEST_HOME/.config/kitty/kitty.conf"
}

@test "update_terminal_font_config writes alacritty family" {
  mkdir -p "$TEST_HOME/.config/alacritty"
  cat >"$TEST_HOME/.config/alacritty/alacritty.toml" <<'EOF'
[font.normal]
family = "monospace"
EOF
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" OSTYPE=linux-gnu bash -c '
    source "$DOTFILES_DIR/lib/helpers.sh"
    source "$DOTFILES_DIR/lib/fonts.sh"
    nerd_font_fc_resolve() { return 1; }
    update_terminal_font_config alacritty "$(nerd_font_family_for_terminal caskaydia alacritty)"
  '
  [ "$status" -eq 0 ]
  grep -q 'family = "CaskaydiaCove Nerd Font Mono"' "$TEST_HOME/.config/alacritty/alacritty.toml"
}
