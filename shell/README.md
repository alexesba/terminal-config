# shell/

Configuration shared by **bash** and **zsh**. Entry point is `../rc.sh` (symlinked to `~/.zshrc` or `~/.bashrc`).

## Layout

```
shell/
├── os-config.sh          # Dispatches to bash.sh or zsh.sh
├── aliases.sh            # Loads built-in aliases + optional ~/.bash_aliases
├── aliases/default.sh    # Git, vim, open, reload, etc.
├── custom.sh.example     # Template for personal overrides (→ custom.sh, gitignored)
├── common/               # Shared by both shells
│   ├── functions.sh      # tmux-start, restore_db
│   ├── dircolors.sh
│   ├── rbenv.sh
│   ├── fzf.sh
│   ├── nvmrc.sh          # load-nvmrc() body
│   └── gogh/
│       ├── colorscheme.sh
│       ├── preview.sh
│       └── persist.sh
├── bash/                 # Bash-only (PROMPT_COMMAND, readline, etc.)
│   ├── ps1.sh + themes/
│   └── …
└── zsh/                  # Zsh-only (vcs_info, zle, chpwd hooks, etc.)
    ├── ps1.sh + themes/
    └── …
```

## Personal overrides

Copy `custom.sh.example` → `custom.sh` (or let `rc.sh` create it on first run). Set `ZSH_THEME`, `TERMINAL`, `GOGH_DIR`, tokens, and machine-specific PATH there.
