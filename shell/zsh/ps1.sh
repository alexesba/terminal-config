autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# ── vcs_info base setup (formats are overridden per theme) ────────────────────
zstyle ':vcs_info:*' enable git
add-zsh-hook precmd vcs_info

# ── Git dirty state ───────────────────────────────────────────────────────────
function _precmd_git_dirty() {
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    _git_dirty=" %F{yellow}✗%f"
  else
    _git_dirty=""
  fi
}

add-zsh-hook precmd _precmd_git_dirty

# ── Background / paused jobs ──────────────────────────────────────────────────
# $jobtexts is a zsh builtin associative array: job_id -> command string
# Displays grouped counts per program, e.g.: ⏸ 2[nvim], 1[ruby]
function _precmd_jobs() {
  if (( ${#jobstates} == 0 )); then
    _jobs_prompt=""
    return
  fi

  local -A counts=()
  local job
  for job in ${(k)jobtexts}; do
    local prog="${jobtexts[$job]%% *}"
    (( counts[$prog]++ ))
  done

  local parts=()
  for prog in ${(k)counts}; do
    parts+=("%F{yellow}${counts[$prog]}%F{white}[${prog}]%f")
  done

  _jobs_prompt=" %F{yellow}⏸ ${(j:, :)parts}%f"
}

add-zsh-hook precmd _precmd_jobs

# ── Shell settings ────────────────────────────────────────────────────────────
# CLICOLOR/LSCOLORS live in dircolors.sh, which both shells source.
setopt PROMPT_SUBST

# ── Theme loader ──────────────────────────────────────────────────────────────
# Override by setting ZSH_THEME in ~/.local.sh before loader.sh runs.
# Example:  export ZSH_THEME="minimal"
# To create your own theme add a file to shell/zsh/themes/<name>.sh
# and define PROMPT (and optionally RPROMPT) using the shared variables:
#   ${vcs_info_msg_0_}  – git branch info (format defined per theme)
#   ${_git_dirty}       – yellow ✗ when working tree is dirty
#   ${_jobs_prompt}     – yellow ⏸ N[prog] for each paused job group
_ZSH_THEME="${ZSH_THEME:-robbyrussell}"
_theme_file="$DOTFILES_DIR/shell/zsh/themes/${_ZSH_THEME}.sh"

if [[ -f "$_theme_file" ]]; then
  source "$_theme_file"
else
  echo "zsh prompt: theme '${_ZSH_THEME}' not found, falling back to robbyrussell" >&2
  source "$DOTFILES_DIR/shell/zsh/themes/robbyrussell.sh"
fi
