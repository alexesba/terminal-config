autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# ── vcs_info ──────────────────────────────────────────────────────────────────
# check-for-changes enables %c (staged) and %u (unstaged) — no git status call
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   '%F{blue}+%f'    # staged
zstyle ':vcs_info:git:*' unstagedstr '%F{red}!%f'     # unstaged
zstyle ':vcs_info:git:*' formats       ' %F{cyan}(%b%f%c%u%F{cyan})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%a%f%c%u%F{yellow})%f'

add-zsh-hook precmd vcs_info

# ── Background jobs ───────────────────────────────────────────────────────────
# ${#jobstates} is a zsh builtin — no subshell needed
function _precmd_jobs() {
  local count=${#jobstates}
  if (( count > 0 )); then
    _jobs_prompt="%F{yellow}⚙ ${count}%f "
  else
    _jobs_prompt=""
  fi
}

add-zsh-hook precmd _precmd_jobs

# ── Prompt ────────────────────────────────────────────────────────────────────
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
setopt PROMPT_SUBST

PROMPT='%F{green}%n%f@%F{red}%~%f${vcs_info_msg_0_} ${_jobs_prompt}'$'\n%F{yellow}~> %f'
