# terminal-config

[![Specs](https://github.com/alexesba/terminal-config/actions/workflows/ci.yml/badge.svg)](https://github.com/alexesba/terminal-config/actions/workflows/ci.yml)

Personal dotfiles for zsh/bash — robbyrussell-style prompt, theme system, sensible aliases, and one-command setup on macOS, Linux, and WSL.

---

## What's included

| Area | Files |
|---|---|
| **Shell prompt** | `shell/{zsh,bash}/ps1.sh` — theme loaders; `shell/{zsh,bash}/themes/` |
| **Aliases** | `shell/aliases/default.sh` — git, vim, open, navigation (always loaded) |
| **History** | 1 million entries, timestamps, deduplication |
| **NVM** | Auto-switches Node version on `cd` via `.nvmrc` |
| **rbenv** | Ruby version management |
| **Python venv** | Auto-activates `./venv` on `cd` |
| **tig** | Git text-mode browser (`alias tig` in aliases) |
| **FZF** | Fuzzy file finder with `rg`/`bat` preview |
| **zsh-autosuggestions** | History + completion suggestions as you type |
| **tmux** | `tmux.conf.example` — copied to `~/.tmux.conf` |
| **Terminal emulators** | `terminal-emulators/*.example` — copied to `~/.config/` (not symlinked) |
| **Color schemes** | `colorscheme` — fuzzy-pick 250+ Gogh themes with a live preview |
| **WSL support** | Clipboard, `open` alias, package manager detection |

---

## Requirements

- **macOS**: [Homebrew](https://brew.sh) installed
- **Linux / WSL**: `apt-get`, `dnf`, or `pacman`
- **All**: `git`, `curl`, `zsh` or `bash`

---

## Install

```bash
git clone https://github.com/alexesba/terminal-config.git ~/Projects/terminal-config
cd ~/Projects/terminal-config
./install.sh
```

`install.sh` is fully interactive:

1. **Questions** — each prompt collapses to a single `✓` line after you answer (shell, tmux, terminal + Nerd Font, tools, etc.). Re-running defaults to your saved terminal/font from `~/.local.sh`.
2. **Summary** — shows everything that will be installed and asks `Proceed?` before changing anything.
3. **Progress** — runs each step with a progress bar; completed steps become `✓ i/total` lines with detail output kept underneath.

It never overwrites files without backing them up (creates `.old` alongside the original). Say no at the summary step to abort with zero changes.

![install.sh summary screen](doc/screenshots/install-summary.png)

---

## Update

```bash
cd ~/Projects/terminal-config
./update.sh
```

Pulls the latest changes and refreshes managed shell RC wrappers (and any legacy symlinks still pointing into this repo). Safe to run at any time.

---

## Tests

CI runs on every push/PR via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

- `bash -n` syntax check on all `*.sh` files
- [shellcheck](https://www.shellcheck.net/) on install/update scripts and `lib/` (sourced `shell/` fragments are syntax-checked via bats smoke tests)
- [bats-core](https://github.com/bats-core/bats-core) tests in `tests/` for helpers, fonts, and shell smoke tests

Run locally:

```bash
brew install bats-core shellcheck   # macOS
./scripts/test.sh
```

What is covered:

| Suite | Focus |
|---|---|
| `tests/helpers.bats` | `link_file`, template copy/migrate, `set_env_var`, uninstall helpers, `is_colorscheme_terminal` |
| `tests/fonts.bats` | Font substitution, `~/.local.sh` parsing, font id resolution |
| `tests/tui.bats` | Progress bar geometry, step begin/end collapse helpers |
| `tests/smoke.bats` | Syntax of install/update scripts; bash/zsh load `colorscheme` and `reload`; bootstrap quiet mode |

Full interactive `install.sh` / `bootstrap.sh` flows are not automated — use the manual checklist below before releases.

**Manual smoke checklist**

1. Fresh `./install.sh` on a test machine (or VM): questions collapse cleanly, summary shows correct choices, progress steps complete; shell RC linked, terminal config copied, font substituted
2. `./update.sh`: git pull succeeds; existing local configs not overwritten
3. `./uninstall.sh`: symlinks removed, configs backed up to `*.uninstall.old`, Nerd Font removed if recorded

---

## Uninstall

```bash
cd ~/Projects/terminal-config
./uninstall.sh          # non-interactive — assumes yes to every step
./uninstall.sh -i       # interactive — ask before each step
```

Detaches this machine from the dotfiles repo:

- Removes `~/.zshrc` / `~/.bashrc` wrappers (restores `*.old` if install backed up your previous rc)
- Removes copied configs (`~/.tmux.conf`, terminal emulator configs) — always backed up to `*.uninstall.old` first
- Uninstalls the Nerd Font recorded in `~/.local.sh` (Homebrew cask on macOS, font files in `~/.local/share/fonts/` on Linux)
- Optionally removes empty `~/.bash_aliases` and `~/.config/wezterm/colors.lua`

Does **not** delete the repo, `~/.local.sh`, or other tools installed by `bootstrap.sh` (nvm, fzf, Gogh, TPM, tmux, etc.).

---

## Themes

Set `ZSH_THEME` in `~/.local.sh` (the variable is honored by both shells):

```bash
export ZSH_THEME="robbyrussell"   # ➜  project git:(main) ✗
export ZSH_THEME="classic"        # full path + branch + timestamp RPROMPT
```

Themes live in `shell/zsh/themes/` (zsh, via native `vcs_info`) and `shell/bash/themes/` (bash, via `PROMPT_COMMAND`), and the two are kept visually in sync. To create your own, copy an existing theme for your shell and it will be picked up automatically. See `shell/README.md` for the full layout.

---

## Color schemes

Run `colorscheme` to fuzzy-pick a terminal color scheme from the [Gogh](https://github.com/Gogh-Co/Gogh) collection (250+ themes). The preview fills the top half of the window; the theme list and prompt sit below. Each preview is a mock terminal window painted in the theme's own colors, with the 16-color palette and key hex values underneath:

```bash
colorscheme
```

![colorscheme picker with live preview](doc/screenshots/colorscheme.png)

Press <kbd>Enter</kbd> to apply the highlighted theme. The preview only *reads* each theme, so scrolling never repaints your terminal — only your final pick is applied.

### How it's applied and persisted

`colorscheme` targets the emulator named in the `TERMINAL` environment variable, which `install.sh` sets from your terminal choice (`alacritty` / `kitty` / `wezterm`). You can override it in `~/.local.sh` — the value must be a name [Gogh recognizes](https://github.com/Gogh-Co/Gogh) (e.g. `gnome-terminal`, `konsole`, `foot`), not just the three emulators this repo ships config templates for.

| Terminal | How the pick persists |
|---|---|
| **Kitty / Alacritty** | Gogh writes the colors into their config files, so new windows keep the theme. |
| **WezTerm** | Gogh only themes the current session via escape sequences, so `colorscheme` also writes the palette to `~/.config/wezterm/colors.lua`. Your local `~/.config/wezterm/wezterm.lua` (copied from `wezterm.lua.example`) loads that file and registers it for auto-reload — the pick applies to open windows and survives new ones. Delete `colors.lua` to revert to the default `color_scheme`. |

### Configuration

- **`GOGH_DIR`** — Gogh repo root (defaults to `~/src/gogh`; themes are read from `installs/`).
- **`TERMINAL`** — managed by `install.sh`; set it manually in `~/.local.sh` to override detection.

Install the Gogh themes via `./bootstrap.sh --gogh` (or pick Gogh during `./install.sh`).

---

## Customization

The repo ships **templates** (`*.example`). `install.sh` copies them to your home directory once; after that they are **yours** — edit fonts, keybindings, status bar, etc. without touching git.

| What | Template | Your local file |
|---|---|---|
| Shell overrides | `shell/local.sh.example` | `~/.local.sh` |
| tmux | `tmux.conf.example` | `~/.tmux.conf` |
| Alacritty | `terminal-emulators/alacritty.toml.example` | `~/.config/alacritty/alacritty.toml` |
| Kitty | `terminal-emulators/kitty.conf.example` | `~/.config/kitty/kitty.conf` |
| WezTerm | `terminal-emulators/wezterm.lua.example` | `~/.config/wezterm/wezterm.lua` |

`git pull` updates the templates in the repo; it does **not** change your local copies. To pick up upstream template changes, diff against the `.example` file and merge what you want by hand:

`install.sh` seeds `~/.local.sh` from `shell/local.sh.example` on first run. To create or compare by hand:

```bash
cp shell/local.sh.example ~/.local.sh   # first time only (install.sh does this too)
diff shell/local.sh.example ~/.local.sh # see new example keys
```

For extra aliases only, you can also use a local `~/.bash_aliases` file (not in the repo).

`./update.sh` migrates old dotfiles symlinks automatically: it backs up your current config to `<file>.old`, replaces the symlink with a local copy (preserving your edits), and removes leftover files from the repo (also backed up as `<file>.old`). It never overwrites a config that is already a regular local file.

---

## Tools installed by bootstrap

| Tool | Flag | Purpose |
|---|---|---|
| tmux | `--tmux` | Terminal multiplexer |
| zsh-autosuggestions | `--autosuggestions` | Inline suggestions |
| rbenv | `--rbenv` | Ruby version manager |
| nvm | `--nvm` | Node version manager |
| fzf | `--fzf` | Fuzzy finder |
| ripgrep | `--ripgrep` | Fast file search (used by FZF) |
| bat | `--bat` | Syntax-highlighted cat (used by FZF preview) |
| hub | `--hub` | GitHub CLI wrapper (`alias git=hub`) |
| Gogh | `--gogh` | 250+ terminal color schemes, applied via `colorscheme` |
| tig | `--tig` | Git text-mode interface (used by the `tig` alias) |
| Nerd Font | `--font=ID` | Terminal font (`caskaydia`, `jetbrains`, `fira`, `hack`) |

Run standalone:
```bash
./bootstrap.sh --ripgrep --bat --tig
```

---

## Cross-platform notes

| Platform | Notes |
|---|---|
| **macOS** | Full support. Uses Homebrew for all installs. |
| **Linux** | Detects `apt-get` / `dnf` / `pacman` automatically. |
| **WSL** | `open` alias uses `wslview` (wslu) or `explorer.exe`. Terminal emulator configs belong on the Windows side. |

---

## Fonts

When you pick a terminal emulator during `./install.sh`, you also choose a **Nerd Font** (default: **Caskaydia Cove Nerd Font Propo**). The installer:

1. Installs the font via Homebrew (`brew install --cask font-…`) on macOS, or downloads from [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) on Linux
2. Substitutes `{{FONT_FAMILY}}` in the copied terminal config with your choice
3. Records `TERMINAL_FONT` and `TERMINAL_FONT_ID` in `~/.local.sh` (used on re-run and by `uninstall.sh`)

Reinstall a font standalone:

```bash
./bootstrap.sh --font=caskaydia
```

Available IDs: `caskaydia`, `jetbrains`, `fira`, `hack`.

On WSL, install fonts on the Windows side for GUI terminals.

---

## Credits & acknowledgments

This config builds on the work of others:

- **[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)** (MIT) — the prompt themes in `shell/zsh/themes/` and `shell/bash/themes/` are reimplementations of oh-my-zsh originals (zsh via native `vcs_info`, bash via `PROMPT_COMMAND`): `robbyrussell.sh` after Robby Russell's [`robbyrussell`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#robbyrussell), and `classic.sh` inspired by [`amuse`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#amuse).
- **[Gogh](https://github.com/Gogh-Co/Gogh)** (MIT) — the 250+ terminal color schemes used by the `colorscheme` command.
- **[TPM](https://github.com/tmux-plugins/tpm)** and the **[tmux-plugins](https://github.com/tmux-plugins)** suite (`tmux-sensible`, `tmux-resurrect`, `tmux-continuum`) — tmux plugin management and session persistence.
- **[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)** — patched fonts installed by `install.sh` / `bootstrap.sh --font=…` for terminal emulator configs.

Thanks to all of the above projects and their maintainers.
