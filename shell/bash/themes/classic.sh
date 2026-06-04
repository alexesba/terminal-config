# Classic theme — inspired by oh-my-zsh's "amuse" theme (MIT), rebuilt for bash
# to match shell/zsh/themes/classic.sh.
# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#amuse
#
# Line 1:  ~/full/path on ⎇ branch!  🕐 HH:MM:SS  [⏸ jobs]
# Line 2:  $
# Right:   hostname  (RPROMPT emulation)
#
# The ! is appended to the branch name when the working tree is dirty.

_prompt_render() {
  local cols="${COLUMNS:-80}" host="${HOSTNAME%%.*}"

  # RPROMPT emulation: save cursor, jump to the right edge, print the hostname,
  # restore. The whole thing lives inside \[ \] so readline counts it as zero
  # width and line wrapping stays correct.
  local rprompt="\[\0337\033[$(( cols - ${#host} + 1 ))G\033[0;31m${host}\033[0m\0338\]"

  local git_seg=""
  if [ -n "$_git_branch" ]; then
    git_seg=" $(_c 37)on$(_c 0) $(_c 35)⎇ ${_git_branch}"
    [ -n "$_git_dirty_flag" ] && git_seg="${git_seg}!"
    git_seg="${git_seg}$(_c 0)"
  fi

  PS1="${rprompt}$(_c '1;32')\w$(_c 0)${git_seg} $(_c 33)🕐 \t$(_c 0)${_jobs_prompt}\n\$ "
}
