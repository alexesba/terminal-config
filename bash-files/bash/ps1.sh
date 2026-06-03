COLOR_BLACk="\033[0;30m"
COLOR_BLUE="\033[0;34m"
COLOR_GREEN="\033[0;32m"
COLOR_CYAN="\033[0;36m"
COLOR_RED="\033[0;31m"
COLOR_PURPLE="\033[0;35m"
COLOR_BROWN="\033[0;33m"
COLOR_YELLOW="\033[1;33m"
COLOR_OCHRE="\033[38;5;95m"
COLOR_WHITE="\033[0;37m"
COLOR_RESET="\033[0m"

_USER=${USER_PS1:-'\u'}
HOST=${HOST_PS1:-'\h'}
SEPARATOR=${SEPARATOR_PS1:-'@'}
SIMBOL=${SIMBOL_PS1:-':'}

# Cache git status once per prompt to avoid two subshells
function _git_status_cached {
  _GIT_STATUS_CACHE="$(git status 2>/dev/null)"
}

function git_color {
  if [[ $_GIT_STATUS_CACHE =~ "Changes to be committed" ]]; then
    echo -e $COLOR_BLUE
  elif [[ $_GIT_STATUS_CACHE =~ "Changes not staged for commit" ]]; then
    echo -e $COLOR_RED
  elif [[ $_GIT_STATUS_CACHE =~ "Untracked files" ]]; then
    echo -e $COLOR_CYAN
  elif [[ $_GIT_STATUS_CACHE =~ "Your branch is ahead of" ]]; then
    echo -e $COLOR_WHITE
  elif [[ $_GIT_STATUS_CACHE =~ "nothing to commit" ]]; then
    echo -e $COLOR_GREEN
  else
    echo -e $COLOR_RESET
  fi
}

function git_branch {
  local on_branch="On branch ([^${IFS}]*)"
  local on_commit="HEAD detached at ([^${IFS}]*)"

  if [[ $_GIT_STATUS_CACHE =~ $on_branch ]]; then
    echo "(${BASH_REMATCH[1]})"
  elif [[ $_GIT_STATUS_CACHE =~ $on_commit ]]; then
    echo "(${BASH_REMATCH[1]})"
  fi
}

function backround_jobs {
  jobs -l | awk '{print $5}' | sort | uniq -c | awk '{printf("%s: %s ", $2, $1)}'
}

function set_ps1 {
  _git_status_cached
  HAS_JOBS="$(jobs -p)"
  if [[ -n "$HAS_JOBS" ]]; then
    JOBS="jobs: \[$COLOR_CYAN\] ❇️  \[$COLOR_YELLOW\]$(backround_jobs)\[$COLOR_RESET\]"
  else
    JOBS=""
  fi
  export PS1="\[$COLOR_GREEN\]$_USER\[$COLOR_RESET\]\[$COLOR_WHITE\]$SEPARATOR\[$COLOR_RESET\]\[$COLOR_RED\]$HOST\[$COLOR_RESET\]\[$COLOR_WHITE\]$SIMBOL\[$COLOR_RESET\]\[$COLOR_YELLOW\] \[$COLOR_RESET\]\[$COLOR_CYAN\]\w\[$COLOR_RESET\] \[\$(git_color)\]\$(git_branch)\[$COLOR_RESET\] ${HAS_JOBS:+$JOBS} \n $ "
}
export CLICOLOR=1

export LSCOLORS=ExFxBxDxCxegedabagacad

export PROMPT_COMMAND="set_ps1; $PROMPT_COMMAND"
