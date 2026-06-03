#!/usr/bin/env bash

# Resolve the directory where this script lives, regardless of where it's called from
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/lib/helpers.sh"

printf "${CYAN}${BOLD}"
cat << "EOF"
       _       _    __ _ _             _           _        _ _
    __| | ___ | |_ / _(_) | ___  ___  (_)_ __  ___| |_ __ _| | | ___ _ __
   / _` |/ _ \| __| |_| | |/ _ \/ __| | | '_ \/ __| __/ _` | | |/ _ \ '__|
  | (_| | (_) | |_|  _| | |  __/\__ \ | | | | \__ \ || (_| | | |  __/ |
   \__,_|\___/ \__|_| |_|_|\___||___/ |_|_| |_|___/\__\__,_|_|_|\___|_|
EOF
printf "${RESET}\n"

# ── Detect shell ──────────────────────────────────────────────────────────────
# Prefer the user's configured default shell ($SHELL), fall back to PATH lookup.
if [[ "$SHELL" =~ zsh ]] || command -v zsh &>/dev/null; then
  TEM_SHELL="${SHELL:-$(command -v zsh)}"
  BASHFILE=".zshrc"
elif [[ "$SHELL" =~ bash ]] || command -v bash &>/dev/null; then
  TEM_SHELL="${SHELL:-$(command -v bash)}"
  BASHFILE=".bashrc"
fi

echo -e "${DIM}Installing from: $DOTFILES_DIR${RESET}"
echo -e "${DIM}Detected shell:  $TEM_SHELL → will configure ~/$BASHFILE${RESET}"
echo ""

# ── Gather input ──────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}Let's set up your environment. Answer a few questions first:${RESET}"
echo ""

echo -e "${BOLD}1. Shell RC ($BASHFILE)${RESET}"
echo -e "   ${DIM}Links bash_profile.sh → ~/$BASHFILE${RESET}"
echo    "   Provides aliases, PATH tweaks, and prompt settings."
ask_yn "Install?"
INSTALL_SHELL=$REPLY
echo ""

echo -e "${BOLD}2. tmux (.tmux.conf)${RESET}"
echo -e "   ${DIM}Links tmux.conf → ~/.tmux.conf${RESET}"
echo    "   Custom keybindings, status bar, and plugin settings."
echo    "   tmux binary will be installed if not already present."
ask_yn "Install?"
INSTALL_TMUX=$REPLY
echo ""

echo -e "${BOLD}3. Bash aliases (.bash_aliases)${RESET}"
echo -e "   ${DIM}Links bash-files/bash_aliases.sh → ~/.bash_aliases${RESET}"
echo    "   Shorthand commands and convenience functions."
ask_yn "Install?"
INSTALL_ALIASES=$REPLY
echo ""

echo -e "${BOLD}4. Terminal emulator config${RESET}"
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo -e "   ${YELLOW}⚠${RESET}  WSL detected — terminal emulators (Alacritty, Kitty, WezTerm) run on"
  echo    "      the Windows side. Configure them there, not inside WSL."
  INSTALL_TERMINAL=4
else
  echo    "   Pick a terminal (or skip):"
  echo -e "     ${BOLD}1)${RESET} Alacritty  ${DIM}→ ~/.config/alacritty/alacritty.yml${RESET}"
  echo -e "     ${BOLD}2)${RESET} Kitty      ${DIM}→ ~/.config/kitty/kitty.conf${RESET}"
  echo -e "     ${BOLD}3)${RESET} WezTerm    ${DIM}→ ~/.config/wezterm/wezterm.lua${RESET}"
  echo -e "     ${BOLD}4)${RESET} Skip"
  ask_choice "Choice" 4
  INSTALL_TERMINAL=$REPLY
fi
echo ""

echo -e "${BOLD}5. zsh-autosuggestions${RESET}"
echo -e "   ${DIM}Installed via brew (or cloned to ~/.zsh/zsh-autosuggestions).${RESET}"
echo    "   Suggests commands as you type based on your history."
ask_yn "Install?"
INSTALL_AUTOSUGG=$REPLY
echo ""

echo -e "${BOLD}6. rbenv — Ruby version manager${RESET}"
echo -e "   ${DIM}Installed via brew (macOS) or git clone on Linux.${RESET}"
echo    "   Manages multiple Ruby versions per project via .ruby-version."
ask_yn "Install?"
INSTALL_RBENV=$REPLY
echo ""

echo -e "${BOLD}7. nvm — Node version manager${RESET}"
echo -e "   ${DIM}Installed via the official nvm install script (latest version).${RESET}"
echo    "   Switches Node versions automatically based on .nvmrc files."
ask_yn "Install?"
INSTALL_NVM=$REPLY
echo ""

echo -e "${BOLD}8. FZF — fuzzy finder${RESET}"
echo -e "   ${DIM}Clones FZF into ~/.fzf and runs its installer.${RESET}"
echo    "   Fuzzy search for files, command history, and more."
ask_yn "Install?"
INSTALL_FZF=$REPLY
echo ""

# ── Link dotfiles ─────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}━━━  Linking dotfiles  ━━━${RESET}"
echo ""

if [[ $INSTALL_SHELL =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ Shell RC${RESET}"
  link_file "$DOTFILES_DIR/bash_profile.sh" ~/$BASHFILE
  echo ""
fi

if [[ $INSTALL_TMUX =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ tmux${RESET}"
  link_file "$DOTFILES_DIR/tmux.conf" ~/.tmux.conf
  echo ""
fi

if [[ $INSTALL_ALIASES =~ ^[Yy]$ ]]; then
  echo -e "${BOLD}→ Bash aliases${RESET}"
  link_file "$DOTFILES_DIR/bash-files/bash_aliases.sh" ~/.bash_aliases
  echo ""
fi

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

# ── Delegate tool installation to bootstrap.sh ────────────────────────────────
BOOTSTRAP_FLAGS=()
[[ $INSTALL_TMUX    =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--tmux)
[[ $INSTALL_AUTOSUGG =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--autosuggestions)
[[ $INSTALL_RBENV   =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--rbenv)
[[ $INSTALL_NVM     =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--nvm)
[[ $INSTALL_FZF     =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--fzf)

if [ ${#BOOTSTRAP_FLAGS[@]} -gt 0 ]; then
  bash "$DOTFILES_DIR/bootstrap.sh" "${BOOTSTRAP_FLAGS[@]}"
fi

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  Reloading shell…"
exec $SHELL -l
