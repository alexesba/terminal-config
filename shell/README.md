# shell/

Configuration shared by **bash** and **zsh**. Entry point is `../rc.sh`, sourced from a local `~/.zshrc` or `~/.bashrc` wrapper installed by `install.sh`.

## Layout

```
shell/
├── loader.sh             # Dispatches to bash.sh or zsh.sh
├── aliases.sh            # Loads built-in aliases + optional ~/.bash_aliases
├── aliases/default.sh    # Git, vim, open, reload, etc.
├── custom.sh.example     # Template copied to ~/.custom.sh on first install
├── common/               # Shared by both shells
│   ├── functions.sh      # tmux-start, restore_db
│   ├── dircolors.sh
│   ├── rbenv.sh
│   ├── fzf.sh            # FZF defaults (rg, bat preview for Ctrl-T)
│   ├── fzf/
│   │   └── open.sh       # Ctrl-O / Ctrl-F file finder (Telescope-style)
│   ├── nvmrc.sh          # load-nvmrc() body
│   └── gogh/
│       ├── colorscheme.sh
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

Copy `shell/custom.sh.example` → `~/.custom.sh` (or let `install.sh` do it on first run). Set `ZSH_THEME`, `TERMINAL`, `GOGH_DIR`, tokens, and machine-specific PATH there.
