#LOAD FZF BASH ENHANCEMENTS
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ── File search command: prefer rg > ag > built-in ────────────────────────────
if command -v rg &>/dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
elif command -v ag &>/dev/null; then
  export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ── Preview command: prefer bat > cat ─────────────────────────────────────────
if command -v bat &>/dev/null; then
  FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"
else
  FZF_PREVIEW_COMMAND="cat {} || tree -C {}"
fi

export FZF_DEFAULT_OPTS="--preview-window noborder --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview-window noborder --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
