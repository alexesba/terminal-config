autoload -Uz vcs_info

precmd() {vcs_info}

zstyle ':vcs_info:git:*' formats '%b'

function git_color {
  local git_status="$(git status 2> /dev/null)"
  if [[ $git_status =~ "Changes to be committed" ]]; then
    echo '%F{blue}'
  elif [[ $git_status =~ "Changes not staged for commit" ]]; then
    echo '%F{red}'
  elif [[  $git_status =~ "Untracked files" ]]; then
    echo '%F{magenta}'
  elif [[ $git_status =~ "Your branch is ahead of" ]]; then
    echo '%F{white}'
  elif [[ $git_status =~ "nothing to commit" ]]; then
    echo '%F{green}'
  else
    echo '%f'
  fi
}

function git_branch() {
    branch=${vcs_info_msg_0_}
    if [[ $branch == "" ]]; then
        :
    else
      echo ' (' $(git_color)$branch%f' ) '
    fi
}

function _background_jobs() {
  if [[ -n "$(jobs)" ]]; then
    __jobs="$(jobs -p |awk '{print $5}'|uniq -c|xargs)"
    export background_jobs="%F{yellow}* %F{cyan}${__jobs}%F{yellow} ¯\_(ツ)_/¯"
  else
    export background_jobs=""
  fi
}

export CLICOLOR=1

export LSCOLORS=ExFxBxDxCxegedabagacad

setopt prompt_subst

autoload -Uz add-zsh-hook
add-zsh-hook precmd _background_jobs

PROMPT='%F{green}%n%f@%F{red}%~%f $(git_branch)${background_jobs:+$background_jobs}'$'\n%f%F{yellow}~> %f'
