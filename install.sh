#!/usr/bin/env bash
cat << "EOF"
       _       _    __ _ _             _           _        _ _
    __| | ___ | |_ / _(_) | ___  ___  (_)_ __  ___| |_ __ _| | | ___ _ __
   / _` |/ _ \| __| |_| | |/ _ \/ __| | | '_ \/ __| __/ _` | | |/ _ \ '__|
  | (_| | (_) | |_|  _| | |  __/\__ \ | | | | \__ \ || (_| | | |  __/ |
   \__,_|\___/ \__|_| |_|_|\___||___/ |_|_| |_|___/\__\__,_|_|_|\___|_|
EOF

# Resolve the directory where this script lives, regardless of where it's called from
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"

echo -e "${DIM}Installing from: $DOTFILES_DIR${RESET}"
echo ""

# Links $1 (source) to $2 (destination), idempotently:
#   • already correct symlink  → skips
#   • symlink to wrong target  → removes and relinks
#   • regular file/dir         → backs up then links
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo -e "  ${GREEN}✓${RESET}  $dest already linked — skipping."
      return
    else
      echo -e "  ${YELLOW}⚠${RESET}  $dest points elsewhere — relinking."
      rm "$dest"
    fi
  elif [ -e "$dest" ]; then
    echo -e "  ${YELLOW}⚠${RESET}  $dest already exists — backing up as ${DIM}$dest.old${RESET}"
    mv "$dest" "$dest.old"
  fi

  ln -s "$src" "$dest"
  echo -e "  ${GREEN}✓${RESET}  $dest linked."
}

# Detect shell
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

echo -e "${DIM}Detected shell: $TEM_SHELL → will configure ~/$BASHFILE${RESET}"
echo ""

# ── Gather input ──────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}Let's set up your environment. Answer a few questions first:${RESET}"
echo ""

echo -e "${BOLD}1. Shell RC ($BASHFILE)${RESET}"
echo -e "   ${DIM}Links bash_profile.sh → ~/$BASHFILE${RESET}"
echo    "   Provides aliases, PATH tweaks, and prompt settings."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_SHELL=$REPLY
echo ""

echo -e "${BOLD}2. tmux (.tmux.conf)${RESET}"
echo -e "   ${DIM}Links tmux.conf → ~/.tmux.conf${RESET}"
echo    "   Custom keybindings, status bar, and plugin settings."
echo    "   tmux will be installed via apt/brew if not already present."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_TMUX=$REPLY
echo ""

echo -e "${BOLD}3. Bash aliases (.bash_aliases)${RESET}"
echo -e "   ${DIM}Links bash-files/bash_aliases.sh → ~/.bash_aliases${RESET}"
echo    "   Shorthand commands and convenience functions."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_ALIASES=$REPLY
echo ""

echo -e "${BOLD}4. Terminal emulator config${RESET}"
echo    "   Pick a terminal (or skip):"
echo -e "     ${BOLD}1)${RESET} Alacritty  ${DIM}→ ~/.config/alacritty/alacritty.yml${RESET}"
echo -e "     ${BOLD}2)${RESET} Kitty      ${DIM}→ ~/.config/kitty/kitty.conf${RESET}"
echo -e "     ${BOLD}3)${RESET} WezTerm    ${DIM}→ ~/.config/wezterm/wezterm.lua${RESET}"
echo -e "     ${BOLD}4)${RESET} Skip"
read -p $'   Choice \033[2m[1-4]\033[0m: ' -n 1 -r; echo
INSTALL_TERMINAL=$REPLY
echo ""

echo -e "${BOLD}5. zsh-autosuggestions${RESET}"
echo -e "   ${DIM}Installed via brew (or cloned to ~/.zsh/zsh-autosuggestions).${RESET}"
echo    "   Suggests commands as you type based on your history."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_AUTOSUGG=$REPLY
echo ""

echo -e "${BOLD}7. rbenv — Ruby version manager${RESET}"
echo -e "   ${DIM}Installed via brew (macOS) or git clone on Linux.${RESET}"
echo    "   Manages multiple Ruby versions per project via .ruby-version."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_RBENV=$REPLY
echo ""

echo -e "${BOLD}8. FZF — fuzzy finder${RESET}"
echo -e "   ${DIM}Clones FZF into ~/.fzf and runs its installer.${RESET}"
echo    "   Fuzzy search for files, command history, and more."
read -p $'   Install? \033[2m(y/n)\033[0m ' -n 1 -r; echo
INSTALL_FZF=$REPLY
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}━━━  Installing  ━━━${RESET}"
echo ""

# ── Shell RC ──────────────────────────────────────────────────────────────────
if [[ $INSTALL_SHELL =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ Shell RC${RESET}"
  link_file "$DOTFILES_DIR/bash_profile.sh" ~/$BASHFILE
  echo ""
fi

# ── tmux ──────────────────────────────────────────────────────────────────────
if [[ $INSTALL_TMUX =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ tmux${RESET}"
  if ! command -v tmux &>/dev/null; then
    if [[ "$OSTYPE" =~ ^linux ]]; then
      sudo apt install tmux
    else
      brew install tmux
    fi
  else
    echo -e "  ${GREEN}✓${RESET}  tmux already installed — skipping package install."
  fi
  link_file "$DOTFILES_DIR/tmux.conf" ~/.tmux.conf
  echo ""
fi

# ── Bash aliases ──────────────────────────────────────────────────────────────
if [[ $INSTALL_ALIASES =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ Bash aliases${RESET}"
  link_file "$DOTFILES_DIR/bash-files/bash_aliases.sh" ~/.bash_aliases
  echo ""
fi

# ── Terminal emulator ─────────────────────────────────────────────────────────
if [[ "$INSTALL_TERMINAL" =~ ^[123]$ ]]; then
  echo -e "${BOLD}→ Terminal emulator${RESET}"
  case "$INSTALL_TERMINAL" in
    1)
      mkdir -p ~/.config/alacritty
      source "$DOTFILES_DIR/terminfo/install.sh"
      link_file "$DOTFILES_DIR/terminals/alacritty.yml" ~/.config/alacritty/alacritty.yml
      ;;
    2)
      mkdir -p ~/.config/kitty
      source "$DOTFILES_DIR/terminfo/install.sh"
      link_file "$DOTFILES_DIR/terminals/kitty.conf" ~/.config/kitty/kitty.conf
      ;;
    3)
      mkdir -p ~/.config/wezterm
      link_file "$DOTFILES_DIR/terminals/wezterm.lua" ~/.config/wezterm/wezterm.lua
      ;;
  esac
  echo ""
fi

# ── zsh-autosuggestions ───────────────────────────────────────────────────────
if [[ $INSTALL_AUTOSUGG =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ zsh-autosuggestions${RESET}"
  if [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install zsh-autosuggestions
  else
    if [ -d ~/.zsh/zsh-autosuggestions ]; then
      echo -e "  ${GREEN}✓${RESET}  ~/.zsh/zsh-autosuggestions already exists — skipping."
    else
      mkdir -p ~/.zsh
      git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi
  fi
  echo ""
fi

# ── rbenv ─────────────────────────────────────────────────────────────────────
if [[ $INSTALL_RBENV =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ rbenv${RESET}"
  if command -v rbenv &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  rbenv already installed — skipping."
  else
    if [[ "$OSTYPE" =~ ^darwin ]]; then
      # libffi is required to build Ruby on macOS (especially newer Clang versions)
      echo -e "  Installing dependencies…"
      brew install rbenv ruby-build libffi
      echo -e "  ${GREEN}✓${RESET}  rbenv + ruby-build + libffi installed."
    else
      if [ -d ~/.rbenv ]; then
        echo -e "  ${GREEN}✓${RESET}  ~/.rbenv already exists — skipping clone."
      else
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv
        git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
      fi
    fi
  fi
  echo ""
fi

# ── FZF ───────────────────────────────────────────────────────────────────────
if [[ $INSTALL_FZF =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ FZF${RESET}"
  if [ -d ~/.fzf ]; then
    echo -e "  ${GREEN}✓${RESET}  ~/.fzf already exists — skipping clone."
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi
  echo ""
fi

echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  Reloading shell…"
exec $SHELL -l
