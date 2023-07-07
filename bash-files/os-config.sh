#Load custom methods by OS type

if which zsh > /dev/null; then
  export SHELL=$(which zsh)
  source ~/.config/terminal-config/bash-files/zsh.sh
else
  export SHELL=$(which bash)
  source ~/.config/terminal-config/bash-files/bash.sh
fi

if [ -f ~/.bash_custom ]; then
 . ~/.bash_custom
fi
