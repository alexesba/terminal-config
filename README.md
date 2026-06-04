# terminal-config

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
| **pyenv** | Python version management |
| **FZF** | Fuzzy file finder with `rg`/`bat` preview |
| **zsh-autosuggestions** | History + completion suggestions as you type |
| **tmux** | `tmux.conf` (from `tmux.conf.example`) — status bar, vim panes, TPM plugins |
| **Terminal emulators** | `terminal-emulators/` — Alacritty & Kitty (symlinked); WezTerm (template → `~/.config/wezterm/`) |
| **Colour schemes** | `colorscheme` — fuzzy-pick 250+ Gogh themes with a live preview |
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

`install.sh` is fully interactive — it asks before doing anything and never overwrites files without backing them up (creates `.old` alongside the original).

---

## Update

```bash
cd ~/Projects/terminal-config
./update.sh
```

Pulls the latest changes and re-links any symlinks that are already pointing into this repo. Safe to run at any time.

---

## Themes

Set `ZSH_THEME` in `shell/custom.sh` (the variable is honored by both shells):

```bash
export ZSH_THEME="robbyrussell"   # ➜  project git:(main) ✗
export ZSH_THEME="classic"        # full path + branch + timestamp RPROMPT
```

Themes live in `shell/zsh/themes/` (zsh, via native `vcs_info`) and `shell/bash/themes/` (bash, via `PROMPT_COMMAND`), and the two are kept visually in sync. To create your own, copy an existing theme for your shell and it will be picked up automatically. See `shell/README.md` for the full layout.

---

## Colour schemes

Run `colorscheme` to fuzzy-pick a terminal colour scheme from the [Gogh](https://github.com/Gogh-Co/Gogh) collection (250+ themes). As you move through the list, a preview pane renders each theme live — a mock terminal window painted in the theme's own colours, the full 16-colour palette, and the key hex values:

```bash
colorscheme
```

Press <kbd>Enter</kbd> to apply the highlighted theme. The preview only *reads* each theme, so scrolling never repaints your terminal — only your final pick is applied.

### How it's applied and persisted

`colorscheme` targets the emulator named in the `TERMINAL` environment variable, which `install.sh` sets from your terminal choice (`alacritty` / `kitty` / `wezterm`) — see [Customisation](#customisation) to override.

| Terminal | How the pick persists |
|---|---|
| **Kitty / Alacritty** | Gogh writes the colours into their config files, so new windows keep the theme. |
| **WezTerm** | Gogh only themes the current session via escape sequences, so `colorscheme` also writes the palette to `~/.config/wezterm/colors.lua`. Your local `~/.config/wezterm/wezterm.lua` (copied from `wezterm.lua.example`) loads that file and registers it for auto-reload — the pick applies to open windows and survives new ones. Delete `colors.lua` to revert to the default `color_scheme`. |

### Configuration

- **`GOGH_DIR`** — Gogh repo root (defaults to `~/src/gogh`; themes are read from `installs/`).
- **`TERMINAL`** — managed by `install.sh`; set it manually in `shell/custom.sh` to override detection.

Install the Gogh themes via `./bootstrap.sh --gogh` (or pick Gogh during `./install.sh`).

---

## Customisation

Copy the example and edit freely — this file is gitignored:

```bash
cp shell/custom.sh.example shell/custom.sh
```

Good things to put there: private tokens, extra PATH entries, machine-specific aliases, `GOGH_DIR` for the `colorscheme()` function. For extra aliases only, you can also use a local `~/.bash_aliases` file (not symlinked into the repo).

**tmux** uses the same pattern — copy the example, then edit your local file (symlinked to `~/.tmux.conf`):

```bash
cp tmux.conf.example tmux.conf
```

**WezTerm** is copied into your config directory (not symlinked), so it can sit next to machine-local `colors.lua`:

```bash
mkdir -p ~/.config/wezterm
cp terminal-emulators/wezterm.lua.example ~/.config/wezterm/wezterm.lua
```

`./update.sh` migrates an old dotfiles symlink to a real file automatically.

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
| Gogh | `--gogh` | 250+ terminal colour schemes, applied via `colorscheme` |

Run standalone:
```bash
./bootstrap.sh --ripgrep --bat
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

The repo includes patched fonts for use with the terminal configs:

| File | Font |
|---|---|
| `JetBrains.zip` | JetBrains Mono |
| `OperatorMonoWithIcons.zip` | Operator Mono with Nerd Font icons |
| `Fonts.zip` | Additional patched fonts |
| `patched-font-windows.zip` | Windows-compatible variants |

**macOS**: unzip and double-click to install, or drag to `~/Library/Fonts/`.  
**Linux/WSL**: unzip to `~/.local/share/fonts/` then run `fc-cache -fv`.

---

## Credits & acknowledgements

This config builds on the work of others:

- **[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)** (MIT) — the prompt themes in `shell/zsh/themes/` and `shell/bash/themes/` are reimplementations of oh-my-zsh originals (zsh via native `vcs_info`, bash via `PROMPT_COMMAND`): `robbyrussell.sh` after Robby Russell's [`robbyrussell`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#robbyrussell), and `classic.sh` inspired by [`amuse`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#amuse).
- **[Gogh](https://github.com/Gogh-Co/Gogh)** (MIT) — the 250+ terminal colour schemes used by the `colorscheme` command.
- **[TPM](https://github.com/tmux-plugins/tpm)** and the **[tmux-plugins](https://github.com/tmux-plugins)** suite (`tmux-sensible`, `tmux-resurrect`, `tmux-continuum`) — tmux plugin management and session persistence.
- **Fonts** — JetBrains Mono, Operator Mono, and other patched [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) bundled for use with the terminal configs; trademarks and licenses belong to their respective authors.

Thanks to all of the above projects and their maintainers.
