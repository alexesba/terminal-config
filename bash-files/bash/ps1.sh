# Shared bash prompt engine — mirrors zsh/ps1.sh so both shells give the same
# experience. It recomputes git + job state before each prompt and delegates the
# layout to a theme in bash/themes/<name>.sh, selected via $ZSH_THEME (the same
# variable zsh uses), defaulting to robbyrussell.
#
# A theme file must define a `_prompt_render` function that sets PS1 using the
# shared state below. Available to themes each prompt:
#   $_last_exit       – exit status of the last command (0 = success)
#   $_git_branch      – current branch/short-sha, or "" when not in a repo
#   $_git_dirty       – ready-made " ✗" (yellow) when the tree is dirty, else ""
#   $_git_dirty_flag  – "1" when dirty (for themes that render their own marker)
#   $_jobs_prompt     – ready-made " ⏸ N[prog], M[prog]" for paused/bg jobs
#   _c <code>         – helper emitting a zero-width-safe colour escape

export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Non-printing colour escape: \001/\002 mark zero-width regions so readline keeps
# line-wrapping correct. \033 (not \e) for portability with older bash/printf.
_c() { printf '\001\033[%sm\002' "$1"; }

# Recompute git branch + dirty state and a grouped paused/background-jobs summary.
_prompt_precompute() {
  _git_branch=""
  _git_dirty=""
  _git_dirty_flag=""
  _jobs_prompt=""

  if command -v git >/dev/null 2>&1; then
    local branch
    branch="$(git symbolic-ref --short -q HEAD 2>/dev/null \
      || git rev-parse --short HEAD 2>/dev/null)"
    if [ -n "$branch" ]; then
      _git_branch="$branch"
      if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        _git_dirty_flag=1
        _git_dirty=" $(_c '1;33')✗$(_c 0)"
      fi
    fi
  fi

  # Grouped counts of background/paused jobs, e.g. "2[nvim], 1[ruby]"
  if [ -n "$(jobs -p)" ]; then
    local summary
    summary="$(jobs | awk '{ p=$3; sub(/.*\//, "", p); if (p != "") c[p]++ }
      END { first=1; for (k in c) { printf "%s%d[%s]", (first ? "" : ", "), c[k], k; first=0 } }')"
    [ -n "$summary" ] && _jobs_prompt=" $(_c '1;33')⏸ ${summary}$(_c 0)"
  fi
}

# ── Theme loader ──────────────────────────────────────────────────────────────
# Override by setting ZSH_THEME in bash_custom.sh (shared with zsh). To create a
# theme, add bash-files/bash/themes/<name>.sh defining _prompt_render.
_BASH_THEME="${ZSH_THEME:-robbyrussell}"
_theme_file="$DOTFILES_DIR/bash-files/bash/themes/${_BASH_THEME}.sh"

if [ -f "$_theme_file" ]; then
  source "$_theme_file"
else
  echo "bash prompt: theme '${_BASH_THEME}' not found, falling back to robbyrussell" >&2
  source "$DOTFILES_DIR/bash-files/bash/themes/robbyrussell.sh"
fi

# Runs before every prompt. Capturing $? must be the very first thing, so this
# file is sourced last among PROMPT_COMMAND contributors and prepends itself.
_prompt_precmd() {
  _last_exit=$?
  _prompt_precompute
  _prompt_render
}
export PROMPT_COMMAND="_prompt_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
