# Inspired by oh-my-zsh robbyrussell theme
#
# Line 1:  ➜  dirname git:(branch) ✗  ⏸ jobs
# Line 2:  ❯  (green on success, red on error)

zstyle ':vcs_info:git:*' formats       ' %F{cyan}git:(%F{red}%b%F{cyan})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}git:(%F{red}%b|%a%F{yellow})%f'

PROMPT='%(?.%F{green}➜%f.%F{red}➜%f)  %F{cyan}%1~%f${vcs_info_msg_0_}${_git_dirty}${_jobs_prompt}'$'\n''%(?.%F{green}❯%f.%F{red}❯%f) '
