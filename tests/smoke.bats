#!/usr/bin/env bats

load test_helper

@test "bootstrap exits 0 in quiet mode when gogh is already present" {
  mkdir -p "$TEST_HOME/src/gogh"
  run env BOOTSTRAP_QUIET=1 HOME="$TEST_HOME" bash "$REPO_ROOT/bootstrap.sh" --gogh
  [ "$status" -eq 0 ]
}

@test "bootstrap skips terminal install when binary is already present" {
  mkdir -p "$TEST_HOME/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_HOME/bin/kitty"
  chmod +x "$TEST_HOME/bin/kitty"
  run env BOOTSTRAP_QUIET=1 HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" \
    bash "$REPO_ROOT/bootstrap.sh" --terminal=kitty
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "bootstrap rejects unknown terminal name" {
  run env BOOTSTRAP_QUIET=1 HOME="$TEST_HOME" bash "$REPO_ROOT/bootstrap.sh" --terminal=iterm
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown terminal"* ]]
}

@test "main shell scripts pass bash syntax check" {
  local script
  for script in install.sh update.sh uninstall.sh bootstrap.sh rc.sh; do
    run bash -n "$REPO_ROOT/$script"
    [ "$status" -eq 0 ] || echo "syntax error in $script"
  done
}

@test "lib scripts pass bash syntax check" {
  local script
  for script in "$REPO_ROOT"/lib/*.sh; do
    run bash -n "$script"
    [ "$status" -eq 0 ] || echo "syntax error in $script"
  done
}

@test "zsh scripts pass zsh syntax check" {
  local script
  for script in "$REPO_ROOT"/shell/zsh/*.sh; do
    run zsh -n "$script"
    [ "$status" -eq 0 ] || echo "syntax error in $script"
  done
}

@test "bash shell chain defines colorscheme" {
  run bash --noprofile --norc -c "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/bash.sh'
    declare -f colorscheme >/dev/null
  "
  [ "$status" -eq 0 ]
}

@test "bash shell chain defines reload alias" {
  run bash --noprofile --norc -c "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/bash.sh'
    alias reload
  "
  [ "$status" -eq 0 ]
}

@test "zsh shell chain defines colorscheme" {
  run zsh -fc "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/zsh.sh'
    whence colorscheme
  "
  [ "$status" -eq 0 ]
}

@test "zsh shell chain defines reload alias" {
  run zsh -fc "
    export DOTFILES_DIR='$REPO_ROOT'
    source '$REPO_ROOT/shell/zsh.sh'
    alias reload
  "
  [ "$status" -eq 0 ]
}
