#!/usr/bin/env bats

load test_helper

@test "install_shell_rc_wrapper creates a local wrapper that sources rc.sh" {
  local dotfiles="$REPO_ROOT"
  local src="$dotfiles/rc.sh"
  local dest="$TEST_HOME/.zshrc"

  install_shell_rc_wrapper "$src" "$dest" >/dev/null

  [ -f "$dest" ] && [ ! -L "$dest" ]
  grep -qF '# terminal-config: begin' "$dest"
  grep -qF "source \"$src\"" "$dest"
}

@test "install_shell_rc_wrapper converts a legacy symlink into a wrapper" {
  local dotfiles="$REPO_ROOT"
  local src="$dotfiles/rc.sh"
  local dest="$TEST_HOME/.zshrc"

  ln -s "$src" "$dest"
  install_shell_rc_wrapper "$src" "$dest" >/dev/null

  [ -f "$dest" ] && [ ! -L "$dest" ]
  grep -qF "source \"$src\"" "$dest"
}

@test "install_shell_rc_wrapper preserves existing content below the managed block" {
  local dotfiles="$REPO_ROOT"
  local src="$dotfiles/rc.sh"
  local dest="$TEST_HOME/.bashrc"

  echo 'export NVM_DIR="$HOME/.nvm"' >"$dest"
  install_shell_rc_wrapper "$src" "$dest" >/dev/null

  grep -qF 'export NVM_DIR="$HOME/.nvm"' "$dest"
  grep -qF "source \"$src\"" "$dest"
}

@test "install_shell_rc_wrapper refreshes the source path on update" {
  local dotfiles="$REPO_ROOT"
  local src="$dotfiles/rc.sh"
  local dest="$TEST_HOME/.zshrc"

  install_shell_rc_wrapper "$src" "$dest" >/dev/null
  sed -i.bak 's|source ".*"|source "/old/path/rc.sh"|' "$dest" && rm -f "$dest.bak"
  install_shell_rc_wrapper "$src" "$dest" >/dev/null

  grep -qF "source \"$src\"" "$dest"
  ! grep -qF '/old/path/rc.sh' "$dest"
}

@test "uninstall_shell_rc_if_mine removes wrapper and restores pre-install backup" {
  local dotfiles="$REPO_ROOT"
  local dest="$TEST_HOME/.zshrc"

  install_shell_rc_wrapper "$dotfiles/rc.sh" "$dest" >/dev/null
  echo "pre-install" >"${dest}.old"

  uninstall_shell_rc_if_mine "$dotfiles" "$dest" >/dev/null

  [ -f "$dest" ]
  grep -q "pre-install" "$dest"
  [ -f "${dest}.uninstall.old" ]
  [ ! -f "${dest}.old" ]
}

@test "link_file creates a symlink to the source" {
  local src="$TEST_HOME/src.txt"
  local dest="$TEST_HOME/link.txt"
  echo "hello" >"$src"

  link_file "$src" "$dest" >/dev/null

  [ -L "$dest" ]
  [ "$(readlink "$dest")" = "$src" ]
}

@test "link_file is idempotent when symlink already correct" {
  local src="$TEST_HOME/src.txt"
  local dest="$TEST_HOME/link.txt"
  echo "hello" >"$src"
  ln -s "$src" "$dest"

  link_file "$src" "$dest" >/dev/null

  [ -L "$dest" ]
  [ "$(readlink "$dest")" = "$src" ]
}

@test "link_file backs up an existing regular file" {
  local src="$TEST_HOME/src.txt"
  local dest="$TEST_HOME/link.txt"
  echo "new" >"$src"
  echo "old" >"$dest"

  link_file "$src" "$dest" >/dev/null

  [ -L "$dest" ]
  [ -f "${dest}.old" ]
  grep -q "old" "${dest}.old"
}

@test "install_config_from_template copies example when dest is missing" {
  local dotfiles="$TEST_HOME/dotfiles"
  mkdir -p "$dotfiles"
  echo "template content" >"$dotfiles/app.conf.example"
  local dest="$TEST_HOME/.config/app.conf"

  install_config_from_template "$dotfiles" "app.conf.example" "$dest" >/dev/null

  [ -f "$dest" ] && [ ! -L "$dest" ]
  grep -q "template content" "$dest"
}

@test "install_config_from_template skips an existing local file" {
  local dotfiles="$TEST_HOME/dotfiles"
  mkdir -p "$dotfiles"
  echo "template" >"$dotfiles/app.conf.example"
  local dest="$TEST_HOME/.config/app.conf"
  mkdir -p "$(dirname "$dest")"
  echo "personal" >"$dest"

  install_config_from_template "$dotfiles" "app.conf.example" "$dest" >/dev/null

  grep -q "personal" "$dest"
}

@test "sanitize_alacritty_toml removes deprecated mouse click sections" {
  local toml="$TEST_HOME/alacritty.toml"
  cat >"$toml" <<'EOF'
alt_send_esc = true
enable_experimental_conpty_backend = false
"window.dynamic_title" = true
"window.opacity" = 1.0

[mouse]
hide_when_typing = false

[mouse.double_click]
threshold = 300

[mouse.hints]
modifiers = "None"

[mouse.triple_click]
threshold = 300

[window.dpi]
x = 96.0
y = 96.0

[font]
size = 14
use_thin_strokes = true
ref_test = false
EOF

  _sanitize_alacritty_toml "$toml"

  ! grep -q 'double_click' "$toml"
  ! grep -q 'mouse.hints' "$toml"
  ! grep -q 'window.dpi' "$toml"
  ! grep -q 'triple_click' "$toml"
  ! grep -q 'alt_send_esc' "$toml"
  ! grep -q 'enable_experimental_conpty_backend' "$toml"
  ! grep -q 'window.dynamic_title' "$toml"
  ! grep -q 'window.opacity' "$toml"
  ! grep -q 'use_thin_strokes' "$toml"
  ! grep -q 'ref_test' "$toml"
  grep -q 'hide_when_typing' "$toml"
}

@test "migrate_alacritty_yaml_config renames yaml when toml already exists" {
  local dir="$TEST_HOME/.config/alacritty"
  mkdir -p "$dir"
  echo "window:" >"$dir/alacritty.yml"
  echo "live_config_reload = true" >"$dir/alacritty.toml"

  migrate_alacritty_yaml_config >/dev/null

  [ ! -f "$dir/alacritty.yml" ]
  [ -f "$dir/alacritty.yml.old" ]
  [ -f "$dir/alacritty.toml" ]
}

@test "install_config_from_template substitutes font placeholder in existing file" {
  local dotfiles="$REPO_ROOT"
  local dest="$TEST_HOME/.config/kitty.conf"
  mkdir -p "$(dirname "$dest")"
  echo "font_family {{FONT_FAMILY}}" >"$dest"

  install_config_from_template "$dotfiles" "terminal-emulators/kitty.conf.example" "$dest" \
    "JetBrainsMono Nerd Font" >/dev/null

  grep -q "font_family JetBrainsMono Nerd Font" "$dest"
  ! grep -q '{{FONT_FAMILY}}' "$dest"
}

@test "install_config_from_template migrates a legacy dotfiles symlink" {
  local dotfiles="$TEST_HOME/dotfiles"
  mkdir -p "$dotfiles/legacy"
  echo "legacy content" >"$dotfiles/legacy/app.conf"
  echo "template" >"$dotfiles/app.conf.example"
  local dest="$TEST_HOME/.config/app.conf"
  mkdir -p "$(dirname "$dest")"
  ln -s "$dotfiles/legacy/app.conf" "$dest"

  install_config_from_template "$dotfiles" "app.conf.example" "$dest" >/dev/null

  [ -f "$dest" ] && [ ! -L "$dest" ]
  grep -q "legacy content" "$dest"
  [ -f "${dest}.old" ]
  grep -q "legacy content" "${dest}.old"
}

@test "set_env_var appends a new export" {
  local file="$TEST_HOME/custom.sh"
  touch "$file"

  set_env_var "$file" TERMINAL "wezterm" >/dev/null

  grep -q 'export TERMINAL="wezterm"' "$file"
}

@test "set_env_var replaces an existing export" {
  local file="$TEST_HOME/custom.sh"
  printf '%s\n' 'export TERMINAL="kitty"' >"$file"

  set_env_var "$file" TERMINAL "wezterm" >/dev/null

  [ "$(grep -c 'export TERMINAL=' "$file")" -eq 1 ]
  grep -q 'export TERMINAL="wezterm"' "$file"
}

@test "set_env_var replaces a commented placeholder export" {
  local file="$TEST_HOME/custom.sh"
  printf '%s\n' '# export TERMINAL=alacritty' >"$file"

  set_env_var "$file" TERMINAL "wezterm" >/dev/null

  grep -q 'export TERMINAL="wezterm"' "$file"
  ! grep -q '# export TERMINAL=' "$file"
}

@test "uninstall_copied_config removes file and creates backup" {
  local dotfiles="$REPO_ROOT"
  local dest="$TEST_HOME/.tmux.conf"
  echo "my tmux" >"$dest"

  uninstall_copied_config "$dotfiles" "$dest" >/dev/null

  [ ! -f "$dest" ]
  [ -f "${dest}.uninstall.old" ]
  grep -q "my tmux" "${dest}.uninstall.old"
}

@test "uninstall_symlink_if_mine removes symlink and restores pre-install backup" {
  local dotfiles="$REPO_ROOT"
  local dest="$TEST_HOME/.zshrc"
  echo "pre-install" >"${dest}.old"
  ln -s "$dotfiles/rc.sh" "$dest"

  uninstall_symlink_if_mine "$dotfiles" "$dest" >/dev/null

  [ ! -L "$dest" ]
  [ -f "$dest" ]
  grep -q "pre-install" "$dest"
}

@test "confirm_yes proceeds in non-interactive mode" {
  CONFIRM_INTERACTIVE=false
  run confirm_yes "Remove anything?"
  [ "$status" -eq 0 ]
}

@test "remove_legacy_repo_copy deletes repo file when local copy exists" {
  local dotfiles="$TEST_HOME/dotfiles"
  mkdir -p "$dotfiles"
  local repo_file="$dotfiles/legacy.conf"
  local dest="$TEST_HOME/.config/legacy.conf"
  echo "stale in repo" >"$repo_file"
  mkdir -p "$(dirname "$dest")"
  echo "local copy" >"$dest"

  remove_legacy_repo_copy "$repo_file" "$dest" >/dev/null

  [ ! -f "$repo_file" ]
  [ -f "${repo_file}.old" ]
  grep -q "stale in repo" "${repo_file}.old"
}

@test "is_colorscheme_terminal accepts gogh-supported terminals and rejects others" {
  for term in alacritty kitty wezterm konsole foot tilix terminator; do
    run is_colorscheme_terminal "$term"
    [ "$status" -eq 0 ]
  done
  # gogh prefix cases
  run is_colorscheme_terminal gnome-terminal
  [ "$status" -eq 0 ]
  run is_colorscheme_terminal gnome-terminal-server
  [ "$status" -eq 0 ]
  run is_colorscheme_terminal io.elementary.terminal
  [ "$status" -eq 0 ]
  # unsupported / empty
  run is_colorscheme_terminal iterm
  [ "$status" -ne 0 ]
  run is_colorscheme_terminal foobar
  [ "$status" -ne 0 ]
  run is_colorscheme_terminal ""
  [ "$status" -ne 0 ]
}

@test "migrate_local_sh copies legacy shell/custom.sh to ~/.local.sh" {
  local dotfiles="$TEST_HOME/terminal-config"
  mkdir -p "$dotfiles/shell"
  echo 'export TERMINAL=kitty' >"$dotfiles/shell/custom.sh"

  run migrate_local_sh "$dotfiles"
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.local.sh" ]
  grep -q 'TERMINAL=kitty' "$TEST_HOME/.local.sh"
  [ ! -f "$dotfiles/shell/custom.sh" ]
}

@test "migrate_local_sh copies legacy ~/.custom.sh to ~/.local.sh" {
  local dotfiles="$TEST_HOME/terminal-config"
  mkdir -p "$dotfiles/shell"
  echo 'export TERMINAL=wezterm' >"$TEST_HOME/.custom.sh"

  run migrate_local_sh "$dotfiles"
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.local.sh" ]
  grep -q 'TERMINAL=wezterm' "$TEST_HOME/.local.sh"
  [ ! -f "$TEST_HOME/.custom.sh" ]
}

@test "migrate_local_sh is a no-op when ~/.local.sh already exists" {
  local dotfiles="$TEST_HOME/terminal-config"
  mkdir -p "$dotfiles/shell"
  echo 'export TERMINAL=wezterm' >"$TEST_HOME/.local.sh"
  echo 'export TERMINAL=kitty' >"$dotfiles/shell/custom.sh"

  run migrate_local_sh "$dotfiles"
  [ "$status" -eq 0 ]
  grep -q 'TERMINAL=wezterm' "$TEST_HOME/.local.sh"
  [ -f "$dotfiles/shell/custom.sh" ]
}

@test "needs_shell_rc_wrapper marks dotfiles-integrated install options" {
  for opt in ALIASES AUTOSUGG RBENV NVM FZF GOGH; do
    run needs_shell_rc_wrapper "$opt"
    [ "$status" -eq 0 ]
  done
  for opt in TMUX RIPGREP BAT HUB TIG; do
    run needs_shell_rc_wrapper "$opt"
    [ "$status" -ne 0 ]
  done
}

@test "needs_fzf_for_install marks FZF-integrated install options" {
  for opt in RIPGREP BAT GOGH; do
    run needs_fzf_for_install "$opt"
    [ "$status" -eq 0 ]
  done
  for opt in TMUX HUB TIG FZF NVM; do
    run needs_fzf_for_install "$opt"
    [ "$status" -ne 0 ]
  done
}

@test "wsl_wezterm_detected_p finds wezterm.exe under Windows profile" {
  mkdir -p "$TEST_HOME/win/AppData/Local/Programs/WezTerm"
  touch "$TEST_HOME/win/AppData/Local/Programs/WezTerm/wezterm.exe"
  run env WSL_DISTRO_NAME=Ubuntu bash -c '
    source "$REPO_ROOT/lib/helpers.sh"
    wsl_windows_home() { printf "%s\n" "'"$TEST_HOME/win"'"; }
    wsl_wezterm_detected_p
  ' REPO_ROOT="$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "configure_wsl_wezterm_local_sh writes TERMINAL and WEZTERM_CONFIG_DIR" {
  mkdir -p "$TEST_HOME/win/.config/wezterm"
  local file="$TEST_HOME/.local.sh"
  touch "$file"
  run env HOME="$TEST_HOME" WSL_DISTRO_NAME=Ubuntu bash -c '
    source "$REPO_ROOT/lib/helpers.sh"
    wsl_windows_home() { printf "%s\n" "'"$TEST_HOME/win"'"; }
    wsl_wezterm_detected_p() { return 0; }
    configure_wsl_wezterm_local_sh "'"$file"'"
  ' REPO_ROOT="$REPO_ROOT"
  [ "$status" -eq 0 ]
  grep -q 'export TERMINAL="wezterm"' "$file"
  grep -q 'export WEZTERM_CONFIG_DIR="'"$TEST_HOME/win/.config/wezterm"'"' "$file"
}
