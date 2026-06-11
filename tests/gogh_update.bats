#!/usr/bin/env bats

load test_helper

@test "gogh update.sh fails when repo is missing" {
  run bash "$REPO_ROOT/shell/common/gogh/update.sh" "$TEST_HOME/missing-gogh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a git repository"* ]]
}

@test "gogh update.sh fails when path is not a git repo" {
  mkdir -p "$TEST_HOME/not-git/installs"
  run bash "$REPO_ROOT/shell/common/gogh/update.sh" "$TEST_HOME/not-git"
  [ "$status" -ne 0 ]
}

@test "colorscheme -h and color_scheme --help show usage" {
  run env DOTFILES_DIR="$REPO_ROOT" bash -c \
    'source "$DOTFILES_DIR/shell/common/gogh/colorscheme.sh"; colorscheme -h'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fuzzy-pick"* ]]
  run env DOTFILES_DIR="$REPO_ROOT" bash -c \
    'source "$DOTFILES_DIR/shell/common/gogh/colorscheme.sh"; color_scheme --help'
  [ "$status" -eq 0 ]
  [[ "$output" == *"colorscheme update"* ]]
}

@test "colorscheme update delegates to update.sh" {
  mkdir -p "$TEST_HOME/src/gogh/.git"
  run env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" GOGH_DIR="$TEST_HOME/src/gogh" \
    bash -c 'source "$DOTFILES_DIR/shell/common/gogh/colorscheme.sh"; colorscheme update'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Updating Gogh"* ]]
}
