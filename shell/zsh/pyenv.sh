# Auto-activate a project-local ./venv on directory change, and deactivate when
# leaving. Mirrors bash/pyenv.sh.
load-pyenv() {
  local localpyenv=./venv
  [[ -d $localpyenv ]] && source $localpyenv/bin/activate > /dev/null 2>&1
  [[ ! -d $localpyenv ]] && [[ -n "${VIRTUAL_ENV:-}" ]] && deactivate > /dev/null 2>&1
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd load-pyenv
load-pyenv  # also run on shell start for the current directory
