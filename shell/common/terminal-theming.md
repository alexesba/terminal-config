# Terminal detection & tmux theming

**Developer documentation** — how detection, theming, and tmux hooks work internally.
End-user commands live in the root [README.md](../../README.md). Function-level notes
are in the script sources (`terminal_detect.sh`, `terminal_use.sh`, `gogh/*`, etc.).

---

## Problem we are solving

| Emulator | How Gogh applies a theme | Inside tmux |
|---|---|---|
| **Kitty / Alacritty** | Writes config files (`colors.conf`, `alacritty.toml`) | Panes inherit the outer terminal's palette — **no per-pane config** |
| **WezTerm** | OSC escape sequences (live, per-pane) | New panes do not read `colors.lua`; tmux 3.6+ hooks re-send OSC to each `#{pane_tty}` |

`~/.local.sh` stores an **install default** (`TERMINAL=wezterm`). That is not always the emulator hosting the current window (e.g. Alacritty tab with default still `wezterm`). Auto-detect sets **`TERMINAL` for this shell/session** so `colorscheme` targets the right app.

**Failure mode we hit:** tmux hooks (`~/.tmux/apply-gogh-theme.sh`) ran in Kitty/Alacritty and applied **WezTerm OSC** to panes because `~/.local.sh` or gogh state said `wezterm`. Panes then looked like a wrong/brown palette until OSC overrides were cleared.

---

## Data flow (high level)

```
~/.local.sh          install default TERMINAL (persistent)
       │
       ▼
detect_terminal_emulator()   ← outer emulator (env, client walk, …)
       │
       ▼
sync_terminal_to_host()      ← export TERMINAL; tmux set-environment TERMINAL
       │
       ├── colorscheme / apply_saved  → Gogh → config file or OSC
       │
       └── tmux hooks (apply_persisted) → WezTerm OSC only if host is WezTerm
```

**Persistence:** `~/.local/state/gogh/current` holds `name=`, `file=`, `terminal=` (last theme + which emulator it was applied for). **`terminal=` in state is not trusted alone for tmux hooks** — the outer host wins.

---

## Files & responsibilities

| File | Role |
|---|---|
| `terminal_detect.sh` | Detect hosting emulator (`alacritty` / `kitty` / `wezterm`) |
| `terminal_use.sh` | `use-terminal` command; `sync_terminal_to_host`; auto-sync on shell start |
| `gogh/apply_persisted.sh` | Installed as `~/.tmux/apply-gogh-theme.sh` — **WezTerm-only** tmux hooks |
| `gogh/clear_tmux_pane_colors.sh` | Strip tmux 3.6+ per-pane OSC palette (OSC 104/110/111) |
| `gogh/reload_kitty.sh` | Clear pane OSC, then `SIGUSR1` Kitty |
| `gogh/reload_alacritty.sh` | Clear pane OSC, then `touch` alacritty.toml |
| `lib/tmux_sessions.sh` | `tmux-start` → sync TERMINAL + reload file-based emulator |
| `tmux.conf.example` | `update-environment "TERMINAL"`; WezTerm-only gogh hooks |

Scripts are invoked as `bash path/to/script.sh` so they always run under **bash** even when the interactive shell is **zsh** (see [Why bash?](#why-bash)).

---

## `terminal_detect.sh`

### `detect_terminal_emulator`

Public entry. Prints one of `alacritty`, `kitty`, `wezterm`, or exits 1.

**Detection order inside tmux** (order matters — learned from production bugs):

1. **`_detect_terminal_client_walk`** — walk process tree from `#{client_pid}` to find Alacritty/Kitty/WezTerm.app. **Most reliable** for “who is hosting this tmux client?”
2. **`_detect_terminal_env`** — `KITTY_WINDOW_ID`, `ALACRITTY_SOCKET`, `WEZTERM_PANE`, etc. Works outside tmux; often **missing inside tmux panes**.
3. **`_detect_terminal_parents`** — walk from `$$` (shell pid). Fallback when client walk fails.
4. **`_detect_terminal_session_env`** — `tmux show-environment TERMINAL`. **Last resort only** — often stale (`wezterm` from `~/.local.sh` via `update-environment`).

We intentionally **do not** trust session `TERMINAL` before client walk: it was the root cause of “detect says wezterm inside Alacritty”.

### `_normalize_detected_terminal`

Sanitize garbage values (e.g. `"alacritty"; export TERMINAL;` from a bad eval into tmux session env). Only accepts the three supported names.

### `_terminal_process_comm`

Uses `ps comm=` with `ucomm=` fallback on macOS where GUI apps sometimes report `-` or truncated names.

---

## `terminal_use.sh`

### When you need `use-terminal`

**Auto-detect is on by default** — interactive shells, `colorscheme`, and `tmux-start` set `TERMINAL` to the emulator hosting the window. Most users never run `use-terminal`.

Use it when:

- Auto-detect picked the wrong emulator (multiple apps installed, unusual tmux layout)
- You want to point `colorscheme` at a different emulator **for this shell only**
- You need to re-apply the saved Gogh theme after switching (`use-terminal kitty apply`)

Inside tmux, new panes inherit session `TERMINAL` (`update-environment` in `tmux.conf.example`) — no `use-terminal` per pane.

### Command reference

| Command | Effect |
|---|---|
| `use-terminal` | fzf menu — pick Alacritty / Kitty / WezTerm (or reset to install default) |
| `use-terminal status` | Show current `TERMINAL`, install default, and detected host |
| `use-terminal detect` | Detect hosting emulator and set `TERMINAL` (same as `sync`) |
| `use-terminal detect --print` | Print detected name only; do not change `TERMINAL` |
| `use-terminal detect --export` | Print `export TERMINAL=…` for scripting |
| `use-terminal sync` | Same as `use-terminal detect` |
| `use-terminal alacritty` / `kitty` / `wezterm` | Manual override for this shell (`TERMINAL_OVERRIDE=1`) |
| `use-terminal kitty apply` | Switch target and re-run saved Gogh theme |
| `use-terminal reset` | Restore `TERMINAL` from `~/.local.sh`; clear override |

Manual picks set **`TERMINAL_OVERRIDE=1`** until `use-terminal reset`. Background auto-detect is suppressed while override is active.

Disable auto-detect entirely: `export TERMINAL_AUTO_DETECT=0` in `~/.local.sh` (see `shell/local.sh.example`). Explicit `use-terminal detect` / `sync` still apply.

Install default (persistent): **`TERMINAL=…`** in `~/.local.sh` (set by `install.sh`). Session override does not change this file.

### `sync_terminal_to_host`

- Respects `TERMINAL_AUTO_DETECT=0` for background auto-sync (shell load, `colorscheme`); **`use-terminal detect` / `sync` always apply** (pass `force=1`).
- Respects manual `TERMINAL_OVERRIDE=1`.
- Calls `detect_terminal_emulator`, then `export TERMINAL=…` when different from current.
- Updates **tmux session** `TERMINAL` via `set-environment` so new panes inherit the right target (`update-environment` in `tmux.conf`).
- Does **not** require config files to exist before syncing (missing config only warns when `TERMINAL_AUTO_DETECT_VERBOSE=1`).

### Auto-sync on shell load

Runs at source time and again on **first prompt** (`precmd` / `PROMPT_COMMAND`) until `TERMINAL` matches detected host. tmux panes sometimes lack full client info during `.zshrc` load.

---

## `gogh/apply_persisted.sh` (tmux hook)

Installed to `~/.tmux/apply-gogh-theme.sh`. Called from `tmux.conf.example` on new pane/window/session (200 ms delay).

### `_wezterm_target`

Returns success **only** when WezTerm OSC should be sent.

1. **`_hook_hosting_terminal`** — client process walk (same idea as `terminal_detect`; duplicated here so the installed copy is self-contained without `DOTFILES_DIR`).
2. If hosting is `alacritty` or `kitty` → **stop** (no OSC).
3. Else consult **`_persisted_terminal`** (env → session `TERMINAL` → gogh state `terminal=`).

We **removed** falling through to `~/.local.sh` grep for `wezterm` — that re-applied WezTerm themes inside Kitty/Alacritty when session env was unset.

### `_apply_to_tty`

Sends Gogh theme OSC to a pane TTY. Only runs when `_wezterm_target` succeeded.

---

## `gogh/clear_tmux_pane_colors.sh`

tmux 3.6+ can store **per-pane** palette overrides via OSC 10/11/4. WezTerm hooks set those; they **stick** on Kitty/Alacritty until cleared.

**`_clear_one`:** sends OSC 104 (reset color table), 110/111 (foreground/background default), and `tmux select-pane -P default`.

**Named session:** `clear_tmux_pane_colors.sh --session <name>` or `GOGH_TMUX_SESSION=<name>` — required for `tmux-start` which runs **outside** tmux (no `$TMUX`), so `--session` alone without a name was a no-op before we added this.

---

## `tmux-start` → `_tmux_sync_session_terminal`

Before attach:

1. `sync_terminal_to_host` (from outer Kitty/Alacritty shell)
2. `tmux set-environment -t <session> TERMINAL …`
3. For **kitty/alacritty**: `reload_*.sh` with `GOGH_TMUX_SESSION` — clear stale WezTerm OSC on all panes and reload config

Without step 3, attaching to an **existing** session kept old OSC colors on panes even after TERMINAL was fixed.

---

## Environment variables

| Variable | Meaning |
|---|---|
| `TERMINAL` | Effective emulator for Gogh this shell (`alacritty` / `kitty` / `wezterm`) |
| `TERMINAL_OVERRIDE=1` | Manual `use-terminal` pick; auto-detect disabled until `use-terminal reset` |
| `TERMINAL_AUTO_DETECT=0` | Disable auto-sync (set in `~/.local.sh`) |
| `TERMINAL_AUTO_DETECT_VERBOSE=1` | Print when auto-sync changes `TERMINAL` |
| `GOGH_TMUX_SESSION` | Target tmux session for pane OSC clear when not inside tmux |
| `GOGH_DIR` | Gogh repo root (themes in `installs/`; default `~/src/gogh`) |

---

## Why bash?

Helper scripts use bash features (`set -u`, `[[ ]]`, process substitution `< <(tmux …)`). The interactive shell may be zsh, but callers use:

```bash
bash "$DOTFILES_DIR/shell/common/gogh/reload_kitty.sh"
```

so the interpreter is explicit. This repo requires **bash on PATH** even for zsh users (macOS `/bin/bash`, Linux, WSL). See README requirements.

---

## Debugging checklist

Inside a tmux pane:

```bash
use-terminal status
echo "TERMINAL=$TERMINAL  TMUX=$TMUX"
tmux show-environment -s TERMINAL
```

If colors are wrong in Kitty/Alacritty only inside tmux:

1. Run `./update.sh` (refresh `~/.tmux/apply-gogh-theme.sh`)
2. `tmux-start` or `GOGH_TMUX_SESSION=<name> bash …/reload_kitty.sh`
3. Confirm `update-environment "TERMINAL"` is in `~/.tmux.conf`
