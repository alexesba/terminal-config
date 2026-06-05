#!/usr/bin/env bats

load test_helper

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
