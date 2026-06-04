# ── Completion system ─────────────────────────────────────────────────────────
# Initialize with caching — only rebuilds the dump once every 24h
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ── Behavior ──────────────────────────────────────────────────────────────────
setopt AUTO_MENU          # Show completion menu on second Tab press
setopt COMPLETE_IN_WORD   # Complete from wherever the cursor is, not just end
setopt ALWAYS_TO_END      # Move cursor to end of word after completion
setopt AUTO_LIST          # List choices immediately on ambiguous completion
setopt LIST_PACKED        # Compact the completion list

# ── Matching strategy ─────────────────────────────────────────────────────────
# 1st pass: exact  2nd: case-insensitive  3rd: partial/substring
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-z}={A-Z}' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=* l:|=*'

# ── Completers ────────────────────────────────────────────────────────────────
# _complete: normal  _match: glob  _approximate: fuzzy (1 typo allowed)
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# ── Menu ──────────────────────────────────────────────────────────────────────
zstyle ':completion:*' menu select           # Arrow-key navigable list
zstyle ':completion:*' special-dirs true     # Always show . and .. for cd

# ── Colors ────────────────────────────────────────────────────────────────────
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"   # Color files like ls
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# ── Grouping & descriptions ───────────────────────────────────────────────────
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{cyan}── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}No matches for: %d%f'

# ── Directories ───────────────────────────────────────────────────────────────
zstyle ':completion:*:cd:*' ignore-parents parent pwd   # Don't suggest cwd in cd
zstyle ':completion:*' squeeze-slashes true             # Collapse // → /
