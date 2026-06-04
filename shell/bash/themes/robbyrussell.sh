# Reimplementation of Robby Russell's "robbyrussell" oh-my-zsh theme (MIT),
# rebuilt for bash to match shell/zsh/themes/robbyrussell.sh.
# https://github.com/ohmyzsh/ohmyzsh
#
# Line 1:  ➜  dirname git:(branch) ✗  ⏸ jobs
# Line 2:  ❯  (green on success, red on error)

_prompt_render() {
  local arrow
  if [ "${_last_exit:-0}" -eq 0 ]; then arrow="$(_c 32)"; else arrow="$(_c 31)"; fi

  local git_seg=""
  [ -n "$_git_branch" ] && \
    git_seg=" $(_c 34)git:($(_c 31)${_git_branch}$(_c 34))$(_c 0)"

  PS1="${arrow}➜$(_c 0)  $(_c 36)\W$(_c 0)${git_seg}${_git_dirty}${_jobs_prompt}\n${arrow}❯$(_c 0) "
}
