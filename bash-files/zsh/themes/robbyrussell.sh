# Reimplementation of Robby Russell's "robbyrussell" oh-my-zsh theme (MIT),
# rebuilt with native zsh vcs_info. https://github.com/ohmyzsh/ohmyzsh
#
# Line 1:  ➜  dirname git:(branch) ✗  ⏸ jobs
# Line 2:  ❯  (green on success, red on error)

zstyle ':vcs_info:git:*' formats       ' %F{blue}git:(%F{red}%b%F{blue})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}git:(%F{red}%b|%a%F{magenta})%f'

PROMPT='%(?.%F{green}➜%f.%F{red}➜%f)  %F{cyan}%1~%f${vcs_info_msg_0_}${_git_dirty}${_jobs_prompt}'$'\n''%(?.%F{green}❯%f.%F{red}❯%f) '
