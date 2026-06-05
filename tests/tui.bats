#!/usr/bin/env bats

load test_helper

@test "tui_bar renders an empty bar at 0" {
  run tui_bar 0 4 4
  [ "$status" -eq 0 ]
  [ "$output" = "[----]" ]
}

@test "tui_bar renders a full bar at completion" {
  run tui_bar 4 4 4
  [ "$status" -eq 0 ]
  [ "$output" = "[####]" ]
}

@test "tui_bar renders a partial bar" {
  run tui_bar 1 2 4
  [ "$output" = "[##--]" ]
}

@test "tui_bar clamps overflow to full width" {
  run tui_bar 9 4 4
  [ "$output" = "[####]" ]
}

@test "tui_bar treats a zero total as 1 without dividing by zero" {
  run tui_bar 0 0 4
  [ "$status" -eq 0 ]
  [ "$output" = "[----]" ]
}

@test "tui_progress prints percentage and step count" {
  run tui_progress 1 4 "nvm"
  [ "$status" -eq 0 ]
  [[ "$output" == *"25%"* ]]
  [[ "$output" == *"1/4"* ]]
  [[ "$output" == *"nvm"* ]]
}

@test "tui_collapse prints a summary line with the label and value" {
  NO_TUI=1 TUI_ENABLED=false run tui_collapse "1. Shell" "zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1. Shell"* ]]
  [[ "$output" == *"zsh"* ]]
}

@test "tui_begin is a no-op when the TUI is disabled" {
  TUI_ENABLED=false run tui_begin
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "tui_step_end prints a checkmark summary when the TUI is disabled" {
  TUI_ENABLED=false run tui_step_end 3 10 "nvm" 2 0
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓"* ]]
  [[ "$output" == *"3/10"* ]]
  [[ "$output" == *"nvm"* ]]
}

@test "tui_step_end prints a warning marker on failure" {
  TUI_ENABLED=false run tui_step_end 3 10 "nvm" 0 1
  [[ "$output" == *"⚠"* ]]
}
