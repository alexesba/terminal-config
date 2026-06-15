#!/usr/bin/env bats

load test_helper

@test "config_list always includes local.sh and bash_aliases" {
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/menus/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" == *$'Shell env & theme\t'"$TEST_HOME/.local.sh"* ]]
  [[ "$output" == *$'Alias overrides\t'"$TEST_HOME/.bash_aliases"* ]]
}

@test "config_list includes tmux when config exists" {
  mkdir -p "$TEST_HOME"
  touch "$TEST_HOME/.tmux.conf"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/menus/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" == *$'tmux\t'"$TEST_HOME/.tmux.conf"* ]]
}

@test "config_list omits missing optional configs" {
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/menus/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" != *"alacritty.toml"* ]]
}

@test "config_preview prints file contents for existing path" {
  local cfg="$TEST_HOME/.local.sh"
  printf 'export TERMINAL=wezterm\n' >"$cfg"
  run env PATH="/usr/bin:/bin" bash "$REPO_ROOT/shell/common/menus/config_preview.sh" "$cfg" "Shell env"
  [ "$status" -eq 0 ]
  [[ "$output" == *'export TERMINAL=wezterm'* ]]
}

@test "config_edit uses config_preview in fzf" {
  grep -q 'config_preview.sh' "$REPO_ROOT/shell/common/menus/config_edit.sh"
  grep -q "' {2} {3}" "$REPO_ROOT/shell/common/menus/config_edit.sh"
}

@test "bindings_help lists help and file finder shortcuts" {
  run bash "$REPO_ROOT/shell/common/bindings/help.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'`help`'* ]]
  [[ "$output" == *'Not used'* ]]
  [[ "$output" == *'Ctrl+O'* ]]
  [[ "$output" == *'Ctrl+T'* ]]
}

@test "bash shell chain defines config and bindings" {
  run bash --noprofile --norc -c "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/bash.sh'
    declare -f config_edit >/dev/null
    declare -f show_bindings >/dev/null
  "
  [ "$status" -eq 0 ]
}

@test "zsh config_open_file does not clobber PATH via local path" {
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/nvim" <<'EOF'
#!/usr/bin/env bash
printf '%s' "$PATH"
EOF
  chmod +x "$TEST_HOME/bin/nvim"
  touch "$TEST_HOME/local-target.sh"

  run zsh -fc "
    export HOME='$TEST_HOME'
    export DOTFILES_DIR='$REPO_ROOT'
    export EDITOR=nvim
    export PATH='$TEST_HOME/bin:/usr/bin:/bin'
    source '$REPO_ROOT/shell/common/menus/config_edit.sh'
    config_open_file '$TEST_HOME/local-target.sh'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TEST_HOME/bin"* ]]
}

@test "zsh shell chain defines config and bindings" {
  run zsh -fc "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/zsh.sh'
    whence config_edit
    whence show_bindings
  "
  [ "$status" -eq 0 ]
}
