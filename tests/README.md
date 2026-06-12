# Tests

Automated checks for this repo. CI runs the same suite as local `./scripts/test.sh` on every push/PR ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)).

## Run locally

```bash
brew install bats-core shellcheck   # macOS
./scripts/test.sh
```

`scripts/test.sh` runs, in order:

1. **`bash -n` / `zsh -n`** — syntax check on all shell scripts
2. **[shellcheck](https://www.shellcheck.net/)** — install/update scripts, `lib/`, `scripts/` (skipped if not installed)
3. **[bats-core](https://github.com/bats-core/bats-core)** — all `tests/*.bats` (required)

Run one file:

```bash
bats tests/terminal_detect.bats
```

Shared setup lives in `test_helper.bash` (`TEST_HOME`, `REPO_ROOT`, helpers like `mock_ps_no_emulator`).

## Suites

| File | Focus |
|---|---|
| `helpers.bats` | `link_file`, template copy/migrate, `set_env_var`, uninstall helpers, `is_colorscheme_terminal` |
| `fonts.bats` | Font substitution, `~/.local.sh` parsing, font id resolution |
| `tui.bats` | Install TUI progress bar and step collapse helpers |
| `smoke.bats` | Syntax of install/update scripts; bash/zsh load `colorscheme` and `reload`; bootstrap quiet mode |
| `terminal_detect.bats` | `detect_terminal_emulator`, `sync_terminal_to_host` |
| `terminal_use.bats` | `use-terminal` CLI and host sync |
| `tmux_sessions.bats` | `tmux-list`, `tmux-start`, `tmux-switch` |
| `update_check.bats` | Throttled dotfiles update hint in `rc.sh` |
| `gogh_apply_persisted.bats` | WezTerm tmux hook (`apply_persisted.sh`) |
| `gogh_clear_tmux_pane_colors.bats` | Pane OSC clear + `reload_kitty.sh` |
| `gogh_reload_alacritty.bats` | Alacritty config reload nudge |
| `gogh_current.bats` | Active theme detection, `persist.sh`, `list.sh` |
| `gogh_deps.bats` | Gogh Python deps and `apply_saved.sh` hints |
| `gogh_preview.bats` | fzf preview layout |
| `gogh_update.bats` | `colorscheme update` / Gogh git pull |

**Not automated:** full interactive `./install.sh` / `./bootstrap.sh` flows — use the manual checklist below before releases.

## Manual smoke checklist

1. Fresh `./install.sh` on a test machine (or VM): questions collapse cleanly, summary shows correct choices, progress steps complete; shell RC linked, terminal config copied, font substituted
2. `./update.sh`: git pull succeeds; existing local configs not overwritten
3. `./uninstall.sh`: symlinks removed, configs backed up to `*.uninstall.old`, Nerd Font removed if recorded

## Writing tests

Detection tests use **`env -i`** and mocked `tmux` / `ps` so they pass when run inside Kitty, Alacritty, or WezTerm (CI has no hosting emulator). See `mock_ps_no_emulator` in `test_helper.bash`.

Implementation notes for terminal theming: [`shell/common/terminal-theming.md`](../shell/common/terminal-theming.md).
