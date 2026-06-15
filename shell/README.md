# shell/

Configuration shared by **bash** and **zsh**. Entry point is `../rc.sh`, sourced from a local `~/.zshrc` or `~/.bashrc` wrapper installed by `install.sh`.

## Layout

```
shell/
├── loader.sh             # Dispatches to bash.sh or zsh.sh
├── aliases.sh            # Loads built-in aliases + optional ~/.bash_aliases
├── aliases/default.sh    # Git, vim, open, reload, etc.
├── local.sh.example      # Template copied to ~/.local.sh on first install
├── common/               # Shared by both shells
│   ├── functions.sh      # sources lib/tmux_sessions.sh; restore_db
│   ├── dircolors.sh
│   ├── rbenv.sh
│   ├── fzf/
│   │   ├── defaults.sh   # FZF env (rg, bat preview for Ctrl-T)
│   │   ├── prompts.sh    # Nerd Font icons for fzf prompts
│   │   ├── rows.sh       # tabular row formatting for fzf menus
│   │   └── open.sh       # Ctrl-O / Ctrl-F file finder (Telescope-style)
│   ├── menus/
│   │   ├── config_edit.sh    # config — edit config files (also: help)
│   │   ├── config_list.sh    # rows for config picker
│   │   ├── config_preview.sh # fzf preview for config files
│   │   ├── help_menu.sh      # help — unified fzf menu
│   │   ├── help_list.sh      # rows for help menu
│   │   └── help_preview.sh   # fzf preview for help rows
│   ├── bindings/
│   │   ├── menu.sh       # bindings — show bindings.md via bat
│   │   ├── help.sh       # prints bindings.md (for scripts/tests)
│   │   ├── bindings.md   # key binding reference (source of truth)
│   │   └── display.sh    # top-aligned markdown display
│   ├── terminal/
│   │   ├── detect.sh     # detect hosting emulator (alacritty / kitty / wezterm)
│   │   ├── use.sh        # use-terminal — fzf picker + auto-sync TERMINAL
│   │   ├── list.sh       # rows / fzf formatting for use-terminal
│   │   └── theming.md    # architecture: detection, theming, why bash
│   ├── nvmrc.sh          # load-nvmrc() body
│   └── gogh/
│       ├── colorscheme.sh
│       ├── apply_saved.sh       # re-apply saved theme for current TERMINAL
│       ├── clear_tmux_pane_colors.sh  # strip tmux per-pane OSC (kitty/alacritty)
│       ├── deps.sh              # Gogh Python deps (Alacritty theming)
│       ├── preview.sh
│       ├── persist.sh           # theme state + colors.lua for WezTerm
│       ├── reload_kitty.sh      # clear pane OSC + SIGUSR1 Kitty
│       └── reload_alacritty.sh  # clear pane OSC + touch alacritty.toml
├── bash/                 # Bash-only (PROMPT_COMMAND, readline, etc.)
│   ├── bindings.sh       # Ctrl-O/F file finder
│   ├── ps1.sh + themes/
│   └── …
└── zsh/                  # Zsh-only (vcs_info, zle, chpwd hooks, etc.)
    ├── bindings.sh       # Ctrl-O/F file finder
    ├── ps1.sh + themes/
    └── …
```

## Personal overrides

Startup loads personal files in this order (see `../rc.sh` and `aliases.sh`):

| File | When it loads | Use it for |
|---|---|---|
| `~/.local.sh` | Early, before `loader.sh` | `ZSH_THEME`, `TERMINAL`, `GOGH_DIR`, `EDITOR`, tokens, PATH — anything the prompt and dotfiles need before the rest of the shell config runs. Seeded from `shell/local.sh.example` by `install.sh`. Optional zsh history overrides: `HISTFILE`, `HISTSIZE`, `SAVEHIST`. |
| `shell/aliases/default.sh` | Via `aliases.sh` | Built-in aliases shipped with this repo (`gs`, `vim=nvim`, `reload`, …). |
| `~/.bash_aliases` | Last in `aliases.sh` | **Alias overrides only** — redefine a repo alias (e.g. `alias gs='git status -sb'`) or add aliases that must win over defaults. Loaded in **both bash and zsh** despite the name (Debian/Ubuntu convention). Optional; `install.sh` can create an empty file as a placeholder. |
| Below the managed block in `~/.zshrc` / `~/.bashrc` | After `rc.sh` finishes | Tool inits (nvm, conda, …) and anything that must run last, including alias overrides. |

**`~/.local.sh` vs `~/.bash_aliases`:** env vars and theme belong in `~/.local.sh`. Alias overrides belong in `~/.bash_aliases` (or below the wrapper in your rc file) because `~/.local.sh` is sourced *before* repo aliases — a conflicting alias there would be overwritten by `aliases/default.sh`.

Copy `shell/local.sh.example` → `~/.local.sh` (or let `install.sh` do it on first run). `update.sh` migrates legacy `shell/custom.sh` and `~/.custom.sh` automatically.

**Quick edit:** run **`help`** for a unified fzf menu — edit config files, show key bindings, pick a color scheme, or switch terminal. Shortcuts: `config`, `bindings`, `colorscheme`, `use-terminal`.

## Terminal detection & tmux theming (developers)

Implementation overview, **`use-terminal` command reference**, and debugging checklist:
**[shell/common/terminal/theming.md](common/terminal/theming.md)**. Per-function notes are in the script sources.
End-user `colorscheme` usage is in the [root README](../README.md#color-schemes).

## Zsh history

Defaults in `zsh/history.sh` (override any of these in `~/.local.sh`):

| Variable | Default | Meaning |
|---|---|---|
| `HISTFILE` | `~/.zsh_history` | Where commands are saved |
| `HISTSIZE` | `50000` | Max lines kept in memory per session |
| `SAVEHIST` | `20000` | Max lines written to disk |

`EXTENDED_HISTORY`, `HIST_FIND_NO_DUPS`, and `INC_APPEND_HISTORY` are set in `zsh/history.sh`. To keep a larger archive, raise `SAVEHIST` (and usually `HISTSIZE`) in `~/.local.sh` before opening a new shell.
