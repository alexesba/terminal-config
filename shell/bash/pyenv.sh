# Auto-activate a project-local ./venv on directory change, and deactivate when
# leaving. Mirrors zsh/pyenv.sh (which uses a chpwd hook); bash has no chpwd, so
# we run it from PROMPT_COMMAND with a PWD guard to only act when the dir changes.
load-pyenv() {
  [ "$PWD" = "$_PYENV_PREV_PWD" ] && return
  _PYENV_PREV_PWD="$PWD"

  if [ -d ./venv ]; then
    # shellcheck disable=SC1091
    source ./venv/bin/activate >/dev/null 2>&1
  elif [ -n "$VIRTUAL_ENV" ]; then
    deactivate >/dev/null 2>&1
  fi
}

PROMPT_COMMAND="load-pyenv; $PROMPT_COMMAND"
