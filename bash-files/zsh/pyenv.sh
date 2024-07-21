
load-pyenv() {
  LOCALPYENV=./venv
  [[ -d $LOCALPYENV ]] && source $LOCALPYENV/bin/activate > /dev/null 2>&1
  [[ ! -d $LOCALPYENV ]] && deactivate > /dev/null 2>&1
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd load-pyenv
