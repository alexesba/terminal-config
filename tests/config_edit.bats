#!/usr/bin/env bats

load test_helper

@test "config_list always includes local.sh and bash_aliases" {
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" == *$'Shell env & theme\t'"$TEST_HOME/.local.sh"* ]]
  [[ "$output" == *$'Alias overrides\t'"$TEST_HOME/.bash_aliases"* ]]
}

@test "config_list includes tmux when config exists" {
  mkdir -p "$TEST_HOME"
  touch "$TEST_HOME/.tmux.conf"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" == *$'tmux\t'"$TEST_HOME/.tmux.conf"* ]]
}

@test "config_list omits missing optional configs" {
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/config_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" != *"alacritty.toml"* ]]
}

@test "bindings_help lists help and file finder shortcuts" {
  run bash "$REPO_ROOT/shell/common/bindings_help.sh"
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

@test "zsh shell chain defines config and bindings" {
  run zsh -fc "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/zsh.sh'
    whence config_edit
    whence show_bindings
  "
  [ "$status" -eq 0 ]
}
