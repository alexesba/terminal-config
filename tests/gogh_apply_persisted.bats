#!/usr/bin/env bats

load test_helper

@test "apply_persisted skips when TERMINAL is not wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
echo should-not-run >&2
exit 1
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=kitty \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *should-not-run* ]]
}

@test "apply_persisted runs saved theme when TERMINAL is wezterm" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
touch "${GOGH_APPLY_MARKER}"
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  GOGH_APPLY_MARKER="$TEST_HOME/gogh-applied"
  rm -f "$GOGH_APPLY_MARKER"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    GOGH_APPLY_PERSISTED_FORCE=1 GOGH_APPLY_MARKER="$GOGH_APPLY_MARKER" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
  [ -f "$GOGH_APPLY_MARKER" ]
}

@test "apply_persisted writes theme output to a tmux pane tty" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;#112233\007'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/fake-pane-tty"
  : >"$pane_tty"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  grep -q $'\033]11;#112233\007' "$pane_tty"
}

@test "apply_persisted pane tty path works with real Gogh theme structure" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=3024-day.sh
EOF
  cat >"$TEST_HOME/gogh/apply-colors.sh" <<'EOF'
#!/usr/bin/env bash
printf '\033]11;%s\007' "${BACKGROUND_COLOR}"
EOF
  chmod +x "$TEST_HOME/gogh/apply-colors.sh"
  cat >"$TEST_HOME/gogh/installs/3024-day.sh" <<'EOF'
#!/usr/bin/env bash
export BACKGROUND_COLOR="#F7F7F7"
apply_theme() { bash "${PARENT_PATH}/apply-colors.sh"; }
PARENT_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
if [ -z "${GOGH_NONINTERACTIVE+no}" ]; then
  apply_theme
else
  apply_theme 1>/dev/null
fi
EOF
  chmod +x "$TEST_HOME/gogh/installs/3024-day.sh"
  pane_tty="$TEST_HOME/fake-pane-tty-gogh"
  : >"$pane_tty"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  grep -q $'\033]11;#F7F7F7\007' "$pane_tty"
}

@test "apply_persisted detects wezterm from local.sh for tmux hook mode" {
  mkdir -p "$TEST_HOME/.local/state/gogh" "$TEST_HOME/gogh/installs"
  cat >"$TEST_HOME/.local.sh" <<'EOF'
export TERMINAL=wezterm
EOF
  cat >"$TEST_HOME/.local/state/gogh/current" <<'EOF'
name=Test
file=theme.sh
EOF
  cat >"$TEST_HOME/gogh/installs/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf 'applied'
EOF
  chmod +x "$TEST_HOME/gogh/installs/theme.sh"
  pane_tty="$TEST_HOME/fake-pane-tty2"
  : >"$pane_tty"
  run env HOME="$TEST_HOME" GOGH_DIR="$TEST_HOME/gogh" \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh" "$pane_tty"
  [ "$status" -eq 0 ]
  [ "$(cat "$pane_tty")" = "applied" ]
}

@test "apply_persisted is a no-op without saved state" {
  run env HOME="$TEST_HOME" TERMINAL=wezterm \
    bash "$REPO_ROOT/shell/common/gogh/apply_persisted.sh"
  [ "$status" -eq 0 ]
}
