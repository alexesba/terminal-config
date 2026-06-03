# terminal-config

Personal dotfiles for zsh/bash — robbyrussell-style prompt, theme system, sensible aliases, and one-command setup on macOS, Linux, and WSL.

---

## What's included

| Area | Files |
|---|---|
| **Shell prompt** | `bash-files/zsh/ps1.sh` — theme loader; `bash-files/zsh/themes/` |
| **Aliases** | `bash-files/bash_aliases.sh` — git, vim, open, navigation |
| **History** | 1 million entries, timestamps, deduplication |
| **NVM** | Auto-switches Node version on `cd` via `.nvmrc` |
| **rbenv** | Ruby version management |
| **pyenv** | Python version management |
| **FZF** | Fuzzy file finder with `rg`/`bat` preview |
| **zsh-autosuggestions** | History + completion suggestions as you type |
| **tmux** | Custom status bar, vim-style panes, cross-platform clipboard |
| **Terminal emulators** | Alacritty, Kitty, WezTerm configs |
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

Set `ZSH_THEME` in `bash-files/bash_custom.sh`:

```bash
export ZSH_THEME="robbyrussell"   # ➜  project git:(main) ✗
export ZSH_THEME="classic"        # full path + branch + timestamp RPROMPT
```

Themes live in `bash-files/zsh/themes/`. To create your own, copy an existing theme and it will be picked up automatically.

---

## Customisation

Copy the example and edit freely — this file is gitignored:

```bash
cp bash-files/bash_custom.sh.example bash-files/bash_custom.sh
```

Good things to put there: private tokens, extra PATH entries, machine-specific aliases, `GOGH_DIR` for the `colorscheme()` function.

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
