alias be='bundle exec'

# Vim aliases
alias vim=nvim
alias vi='nvim --noplugin'
command -v hub &>/dev/null && alias git=hub
alias ls-hidden="ls -la | grep ' \.'"

# User commands
alias git-log='git log --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short  --reverse --all'

# Git aliases
alias ga='git add'
alias gap='git add --patch'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gdc='git diff --cached'
alias gs='git status'
alias :q='exit'
alias :wq='exit'
alias lvim='nvim --clean -u NONE -i NONE'
alias pvim='nvim -u ~/performance.vim'
alias tig='TERM=xterm-256color tig'

if [[ "$OSTYPE" =~ ^linux ]]; then
  # open: WSL → wslview (wslu) or explorer.exe; Linux → xdg-open or gnome-open
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v wslview &>/dev/null; then
      alias open='wslview'
    else
      alias open='explorer.exe'
    fi
  elif command -v xdg-open &>/dev/null; then
    alias open='xdg-open'
  elif command -v gnome-open &>/dev/null; then
    alias open='gnome-open'
  fi
  alias reload='source ~/.zshrc'

else
  alias dns-clean="sudo killall -HUP mDNSResponder"
  alias reload='source ~/.zshrc'
fi

alias gcoft='git branch -a| fzf | xargs git checkout -t'
alias gcof='git branch -a| fzf | xargs git checkout'

alias marp="marp -c $HOME/Projects/marp-diagrams/marp.config.js --allow-local-files "
