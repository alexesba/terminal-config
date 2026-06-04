#!/usr/bin/env bash
# bootstrap.sh — installs development tools based on flags.
#
# Usage:
#   ./bootstrap.sh [--tmux] [--autosuggestions] [--rbenv] [--nvm] [--fzf]
#                  [--ripgrep] [--bat] [--hub]
#
# Can be called by install.sh or run standalone to (re)install individual tools.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/lib/helpers.sh"

DO_TMUX=false
DO_AUTOSUGG=false
DO_RBENV=false
DO_NVM=false
DO_FZF=false
DO_RIPGREP=false
DO_BAT=false
DO_HUB=false
DO_GOGH=false
DO_FONT=""

# ── Parse flags ───────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --tmux)            DO_TMUX=true ;;
    --autosuggestions) DO_AUTOSUGG=true ;;
    --rbenv)           DO_RBENV=true ;;
    --nvm)             DO_NVM=true ;;
    --fzf)             DO_FZF=true ;;
    --ripgrep)         DO_RIPGREP=true ;;
    --bat)             DO_BAT=true ;;
    --hub)             DO_HUB=true ;;
    --gogh)            DO_GOGH=true ;;
    --font=*)
      DO_FONT="${arg#*=}"
      ;;
    --font)
      echo -e "  ${YELLOW}⚠${RESET}  --font requires a value: caskaydia, jetbrains, fira, or hack"
      exit 1
      ;;
    --help)
      echo "Usage: $0 [--tmux] [--autosuggestions] [--rbenv] [--nvm] [--fzf] [--ripgrep] [--bat] [--hub] [--gogh] [--font=ID]"
      echo ""
      echo "Font IDs for --font=: caskaydia (default), jetbrains, fira, hack"
      exit 0
      ;;
    *)
      echo -e "  ${YELLOW}⚠${RESET}  Unknown flag: $arg"
      ;;
  esac
done

if ! $DO_TMUX && ! $DO_AUTOSUGG && ! $DO_RBENV && ! $DO_NVM && ! $DO_FZF && \
   ! $DO_RIPGREP && ! $DO_BAT && ! $DO_HUB && ! $DO_GOGH && [[ -z "$DO_FONT" ]]; then
  echo -e "${YELLOW}No tools selected. Run with --help to see available flags.${RESET}"
  exit 0
fi

echo -e "${CYAN}${BOLD}━━━  Installing tools  ━━━${RESET}"
echo ""

# ── Linux package manager helper ──────────────────────────────────────────────
# Usage: _linux_install <pkg> [<pkg> ...]
_linux_install() {
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  else
    echo -e "  ${YELLOW}⚠${RESET}  Unknown package manager — please install ${BOLD}$*${RESET} manually."
  fi
}

# ── tmux ──────────────────────────────────────────────────────────────────────
if $DO_TMUX; then
  echo -e "${BOLD}→ tmux${RESET}"
  if command -v tmux &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  tmux already installed — skipping."
  elif [[ "$OSTYPE" =~ ^linux ]]; then
    _linux_install tmux xclip
    # On WSL, also install wslu so `wslview` is available as the `open` command
    if grep -qi microsoft /proc/version 2>/dev/null; then
      echo -e "  ${DIM}WSL detected — installing wslu (provides wslview)…${RESET}"
      _linux_install wslu
    fi
  else
    brew install tmux
  fi
  # ── TPM (Tmux Plugin Manager) ───────────────────────────────────────────────
  if [ -d ~/.tmux/plugins/tpm ]; then
    echo -e "  ${GREEN}✓${RESET}  TPM already installed — skipping."
  else
    echo -e "  Installing TPM…"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo -e "  ${GREEN}✓${RESET}  TPM installed. Open tmux and press ${BOLD}prefix + I${RESET} to install plugins."
  fi
  echo ""
fi

# ── zsh-autosuggestions ───────────────────────────────────────────────────────
if $DO_AUTOSUGG; then
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
if $DO_RBENV; then
  echo -e "${BOLD}→ rbenv${RESET}"
  if command -v rbenv &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  rbenv already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
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
  echo ""
fi

# ── nvm ───────────────────────────────────────────────────────────────────────
if $DO_NVM; then
  echo -e "${BOLD}→ nvm${RESET}"
  if [ -d "$HOME/.nvm" ]; then
    echo -e "  ${GREEN}✓${RESET}  ~/.nvm already exists — skipping."
  else
    echo -e "  Fetching latest nvm version…"
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    echo -e "  Installing nvm ${NVM_VERSION}…"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    echo -e "  ${GREEN}✓${RESET}  nvm ${NVM_VERSION} installed."
  fi
  echo ""
fi

# ── FZF ───────────────────────────────────────────────────────────────────────
if $DO_FZF; then
  echo -e "${BOLD}→ FZF${RESET}"
  if [ -d ~/.fzf ]; then
    echo -e "  ${GREEN}✓${RESET}  ~/.fzf already exists — skipping clone."
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi
  echo ""
fi

# ── ripgrep ───────────────────────────────────────────────────────────────────
if $DO_RIPGREP; then
  echo -e "${BOLD}→ ripgrep (rg)${RESET}"
  if command -v rg &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  ripgrep already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install ripgrep
  else
    _linux_install ripgrep
  fi
  echo ""
fi

# ── bat ───────────────────────────────────────────────────────────────────────
if $DO_BAT; then
  echo -e "${BOLD}→ bat${RESET}"
  if command -v bat &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  bat already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install bat
  else
    _linux_install bat
  fi
  echo ""
fi

# ── hub ───────────────────────────────────────────────────────────────────────
if $DO_HUB; then
  echo -e "${BOLD}→ hub${RESET}"
  if command -v hub &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  hub already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install hub
  else
    _linux_install hub
  fi
  echo ""
fi

# ── Gogh — terminal colour schemes ───────────────────────────────────────────
if $DO_GOGH; then
  echo -e "${BOLD}→ Gogh${RESET}"
  local_gogh_dir="${GOGH_DIR:-$HOME/src/gogh}"
  if [ -d "$local_gogh_dir" ]; then
    echo -e "  ${GREEN}✓${RESET}  Gogh already cloned at $local_gogh_dir — skipping."
  else
    echo -e "  Cloning Gogh into $local_gogh_dir…"
    git clone --depth 1 https://github.com/Gogh-Co/Gogh "$local_gogh_dir"
    echo -e "  ${GREEN}✓${RESET}  Gogh installed. Run ${BOLD}colorscheme${RESET} in your shell to pick a theme."
  fi
  echo ""
fi

# ── Nerd Font ─────────────────────────────────────────────────────────────────
if [[ -n "$DO_FONT" ]]; then
  source "$DOTFILES_DIR/lib/fonts.sh"
  echo -e "${BOLD}→ Nerd Font${RESET}"
  if nerd_font_family "$DO_FONT" &>/dev/null; then
    install_nerd_font "$DO_FONT"
  else
    echo -e "  ${YELLOW}⚠${RESET}  Unknown font ID: ${BOLD}${DO_FONT}${RESET}"
    echo -e "      Valid IDs: caskaydia, jetbrains, fira, hack"
    exit 1
  fi
  echo ""
fi

echo -e "${GREEN}${BOLD}Done!${RESET}"
