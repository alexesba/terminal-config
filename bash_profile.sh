# ~/.bashrc: executed by bash(1) for non-login shellskk.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

if [ -f ~/.bash_custom ]; then
  source ~/.bash_custom
fi

export PATH="/usr/local/bin:$PATH"

source ~/.config/terminal-config/bash-files/os-config.sh
