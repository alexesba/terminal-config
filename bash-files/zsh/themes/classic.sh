# Classic theme — inspired by oh-my-zsh's "amuse" theme (MIT), rebuilt with
# native zsh vcs_info. https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#amuse
#
# Line 1:  ~/full/path on ⎇ branch!  🕐 HH:MM:SS  [⏸ jobs]
# Line 2:  $
# Right:   hostname  (RPROMPT)
#
# The ! is appended to the branch name when staged or unstaged changes exist.

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   '%F{magenta}!%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{magenta}!%f'
zstyle ':vcs_info:git:*' formats       ' %F{white}on%f %F{magenta}⎇ %b%f%c%u'
zstyle ':vcs_info:git:*' actionformats ' %F{white}on%f %F{magenta}⎇ %b|%a%f%c%u'

RPROMPT='%F{red}%m%f'

PROMPT='%F{green}%B%~%b%f${vcs_info_msg_0_} %F{yellow}🕐 %*%f${_jobs_prompt}'$'\n''$ '
