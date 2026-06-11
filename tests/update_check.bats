#!/usr/bin/env bats

load test_helper

_mock_git() {
  local mode="${1:-behind}"
  mkdir -p "$TEST_HOME/bin"
  cat >"$TEST_HOME/bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-C" ]]; then
  shift 2
fi
case "\$1" in
  fetch) exit 0 ;;
  rev-parse)
    [[ "\${3:-}" == "@{upstream}" ]] && exit 0
    exit 1
    ;;
  status)
    case "$mode" in
      dirty) echo " M README.md" ;;
    esac
    exit 0
    ;;
  rev-list)
    case "$mode" in
      behind) echo 2 ;;
      clean) echo 0 ;;
    esac
    exit 0
    ;;
esac
exit 0
EOF
  chmod +x "$TEST_HOME/bin/git"
}

_run_update_check() {
  local check_flag="${1:-1}"
  env HOME="$TEST_HOME" DOTFILES_DIR="$REPO_ROOT" XDG_CACHE_HOME="$TEST_HOME/.cache" \
    PATH="$TEST_HOME/bin:$PATH" \
    TERMINAL_CONFIG_UPDATE_CHECK="$check_flag" \
    bash -c '
      source "$1/lib/helpers.sh"
      source "$1/lib/update_check.sh"
      terminal_config_update_check
    ' _ "$REPO_ROOT"
}

@test "update check is disabled when TERMINAL_CONFIG_UPDATE_CHECK=0" {
  _mock_git behind
  mkdir -p "$TEST_HOME/.cache/terminal-config"
  echo 0 >"$TEST_HOME/.cache/terminal-config/last-fetch"

  run _run_update_check 0
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "update check skips when last fetch is recent" {
  _mock_git behind
  mkdir -p "$TEST_HOME/.cache/terminal-config"
  date +%s >"$TEST_HOME/.cache/terminal-config/last-fetch"

  run _run_update_check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "update check prints hint when repo is behind upstream" {
  _mock_git behind
  mkdir -p "$TEST_HOME/.cache/terminal-config"
  echo 0 >"$TEST_HOME/.cache/terminal-config/last-fetch"

  run _run_update_check
  [ "$status" -eq 0 ]
  [[ "$output" == *"terminal-config updates available (2)"* ]]
  [[ "$output" == *"update.sh"* ]]
}

@test "update check stays quiet with a dirty working tree" {
  _mock_git dirty
  mkdir -p "$TEST_HOME/.cache/terminal-config"
  echo 0 >"$TEST_HOME/.cache/terminal-config/last-fetch"

  run _run_update_check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "update check stays quiet when repo matches upstream" {
  _mock_git clean
  mkdir -p "$TEST_HOME/.cache/terminal-config"
  echo 0 >"$TEST_HOME/.cache/terminal-config/last-fetch"

  run _run_update_check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
