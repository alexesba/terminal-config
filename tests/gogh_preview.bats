#!/usr/bin/env bats

load test_helper

@test "gogh preview centers output in the fzf preview pane" {
  local theme="$BATS_TEST_TMPDIR/theme.sh"
  cat >"$theme" <<'EOF'
export PROFILE_NAME="Test Theme"
export BACKGROUND_COLOR="#1a1a1a"
export FOREGROUND_COLOR="#d0d0d0"
export CURSOR_COLOR="#ffffff"
export COLOR_01="#000000"
export COLOR_02="#cc6666"
export COLOR_03="#9ec07c"
export COLOR_04="#e0c06f"
export COLOR_05="#7aa6da"
export COLOR_06="#b294bb"
export COLOR_07="#8abeb7"
export COLOR_08="#d0d0d0"
export COLOR_09="#808080"
export COLOR_10="#cc6666"
export COLOR_11="#9ec07c"
export COLOR_12="#e0c06f"
export COLOR_13="#7aa6da"
export COLOR_14="#b294bb"
export COLOR_15="#8abeb7"
export COLOR_16="#ffffff"
EOF

  run env FZF_PREVIEW_COLUMNS=80 FZF_PREVIEW_LINES=30 \
    bash "$REPO_ROOT/shell/common/gogh/preview.sh" "$theme"
  [ "$status" -eq 0 ]

  local first_nonempty
  first_nonempty=$(printf '%s\n' "$output" | sed -n '/./p' | head -1)
  [[ "$first_nonempty" =~ ^[[:space:]]+ ]]
}
