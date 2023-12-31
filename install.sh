cat << "EOF"
       _       _    __ _ _             _           _        _ _
    __| | ___ | |_ / _(_) | ___  ___  (_)_ __  ___| |_ __ _| | | ___ _ __
   / _` |/ _ \| __| |_| | |/ _ \/ __| | | '_ \/ __| __/ _` | | |/ _ \ '__|
  | (_| | (_) | |_|  _| | |  __/\__ \ | | | | \__ \ || (_| | | |  __/ |
   \__,_|\___/ \__|_| |_|_|\___||___/ |_|_| |_|___/\__\__,_|_|_|\___|_|
EOF

# Shell configuration

if which zsh > /dev/null; then
  TEM_SHELL=$(which zsh)
elif which bash > /dev/null; then
  TEM_SHELL=$(which bash)
fi


if [[ $TEM_SHELL == *'zsh' ]]; then
  BASHFILE=".zshrc"
elif [[ $TEM_SHELL == *'bash' ]]; then
  BASHFILE=".bashrc"
fi

echo "$TEM_SHELL was selected as default shell"

read -p "Do you want to install $BASHFILE config file?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [ -f ~/$BASHFILE ]; then
    echo "$BASHFILE already exist.. performing a backup before link the $BASHFILE"
    mv ~/$BASHFILE ~/$BASHFILE.old
    echo "your previous configuration was renamed as ~/$BASHFILE.old"
  fi

  ln -s ~/.config/nvim/bash_profile.sh ~/$BASHFILE

  echo "$BASHFILE linked correctly!"
fi

read -p "Do you want to install .tmux.conf config file?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
  if [[ "$OSTYPE" =~ ^linux ]]; then
    sudo apt install tmux
  else
    brew install tmux
  fi
  if [ -f ~/.tmux.conf ]; then
    echo ".tmux.conf already exist.. performing a backup before link the .tmux.conf"
    mv ~/.tmux.conf ~/.tmux.conf.old
    echo "your previous configuration was renamed as ~/.tmux.conf.old"
  fi

  ln -s ~/.config/nvim/tmux.conf ~/.tmux.conf


  echo "tmux.conf linked correctly!."
fi

read -p "Do you want to install .bash_aliases config file?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  ln -s ~/.config/nvim/bash-files/bash_aliases.sh ~/.bash_aliases
  echo ".bash_aliases linked correctly!."
fi

read -p "Do you want to install alacritty.yml config file?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then

  mkdir ~/.config/alacritty -p

  if [ -f ~/.config/alacritty/alacritty.yml ]; then
    echo "~/.config/alacritty/alacritty.yml already exist.. performing a backup before link the alacritty.yml"
    mv ~/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml.old
    echo "your previous configuration was renamed as ~/.config/alacritty/alacritty.yml.old"
  fi

  source ~/.config/nvim/terminfo/install.sh

  ln -s ~/.config/nvim/terminals/alacritty.yml ~/.config/alacritty
  echo "alacritty.yml linked correctly!."
fi

read -p "Do you want to install kitty.conf config file?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then

  mkdir ~/.config/kitty -p

  if [ -f ~/.config/kitty/kitty.conf ]; then
    echo "~/.config/kitty/kitty.conf already exist.. performing a backup before link the alacritty.yml"
    mv ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.old
    echo "your previous configuration was renamed as ~/.config/kitty/kitty.conf.old"
  fi

  source ~/.config/nvim/terminfo/install.sh

  ln -s ~/.config/nvim/terminals/kitty.conf ~/.config/kitty
  echo "kitty.conf linked correctly!."
fi

read -p "Do you want to install FZF (command line fuzzy finder)?(y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
fi
