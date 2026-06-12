#!/usr/bin/env bats

load test_helper

@test "help_list includes actions and edit rows" {
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" \
    bash "$REPO_ROOT/shell/common/help_list.sh" rows
  [ "$status" -eq 0 ]
  [[ "$output" == *$'Show key bindings\tbindings\t'* ]]
  [[ "$output" == *$'Color scheme\tcolorscheme\t'* ]]
  [[ "$output" == *$'Switch terminal\tuse-terminal\t'* ]]
  [[ "$output" == *$'Edit · Shell env & theme\tedit:'"$TEST_HOME/.local.sh"* ]]
}

@test "bindings_help documents help command" {
  run bash "$REPO_ROOT/shell/common/bindings_help.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'`help`'* ]]
  [[ "$output" == *'Ctrl+O'* ]]
}

@test "bash shell chain defines help and config_open_file" {
  run bash --noprofile --norc -c "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/bash.sh'
    declare -f help >/dev/null
    declare -f help_menu >/dev/null
    declare -f config_open_file >/dev/null
  "
  [ "$status" -eq 0 ]
}

@test "zsh shell chain defines help" {
  run zsh -fc "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/zsh.sh'
    whence help
    whence config_open_file
  "
  [ "$status" -eq 0 ]
}

@test "bash help delegates to builtin when args given" {
  run bash --noprofile --norc -c "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/bash.sh'
    help read 2>&1 | head -n1
  "
  [ "$status" -eq 0 ]
  [[ "$output" == read* ]]
}
