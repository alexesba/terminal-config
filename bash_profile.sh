# ~/.bashrc: executed by bash(1) for non-login shellskk.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

source ~/.config/terminal-config/bash-files/os-config.sh

export PATH="/usr/local/bin:$PATH"
