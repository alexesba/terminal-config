# Load bash-completion from the first location that exists:
#   • Homebrew (Apple Silicon / Intel) via brew --prefix
#   • common system paths (Linux distros, Intel-mac Homebrew)
if command -v brew &>/dev/null; then
  _bc_prefix="$(brew --prefix 2>/dev/null)"
  if [ -r "$_bc_prefix/etc/profile.d/bash_completion.sh" ]; then
    . "$_bc_prefix/etc/profile.d/bash_completion.sh"
  elif [ -r "$_bc_prefix/etc/bash_completion" ]; then
    . "$_bc_prefix/etc/bash_completion"
  fi
  unset _bc_prefix
fi

if ! declare -F _init_completion &>/dev/null; then
  for _bc in \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion \
    /usr/local/etc/bash_completion; do
    if [ -r "$_bc" ]; then
      . "$_bc"
      break
    fi
  done
  unset _bc
fi
