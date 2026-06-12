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
│   ├── fzf.sh            # FZF defaults (rg, bat preview for Ctrl-T)
│   ├── fzf/
│   │   └── open.sh       # Ctrl-O / Ctrl-F file finder (Telescope-style)
│   ├── nvmrc.sh          # load-nvmrc() body
│   ├── terminal_use.sh   # use-terminal — fzf picker + session TERMINAL override
│   ├── terminal_list.sh  # rows / fzf formatting for use-terminal
│   └── gogh/
│       ├── colorscheme.sh
│       ├── apply_persisted.sh   # WezTerm tmux hook; installed as ~/.tmux/apply-gogh-theme.sh
│       ├── apply_saved.sh       # re-apply saved theme for current TERMINAL
│       ├── deps.sh              # Gogh Python deps (Alacritty theming)
│       ├── preview.sh
│       └── persist.sh
├── bash/                 # Bash-only (PROMPT_COMMAND, readline, etc.)
│   ├── bindings.sh       # Ctrl-O / Ctrl-F → fzf_then_open_in_editor
│   ├── ps1.sh + themes/
│   └── …
└── zsh/                  # Zsh-only (vcs_info, zle, chpwd hooks, etc.)
    ├── bindings.sh       # Ctrl-O / Ctrl-F → fzf_then_open_in_editor
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

## Zsh history

Defaults in `zsh/history.sh` (override any of these in `~/.local.sh`):

| Variable | Default | Meaning |
|---|---|---|
| `HISTFILE` | `~/.zsh_history` | Where commands are saved |
| `HISTSIZE` | `50000` | Max lines kept in memory per session |
| `SAVEHIST` | `20000` | Max lines written to disk |

`EXTENDED_HISTORY`, `HIST_FIND_NO_DUPS`, and `INC_APPEND_HISTORY` are set in `zsh/history.sh`. To keep a larger archive, raise `SAVEHIST` (and usually `HISTSIZE`) in `~/.local.sh` before opening a new shell.
