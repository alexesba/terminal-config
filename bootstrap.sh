#!/usr/bin/env bash
# bootstrap.sh — installs development tools based on flags.
#
# Usage:
#   ./bootstrap.sh [--tmux] [--autosuggestions] [--rbenv] [--nvm] [--fzf]
#                  [--ripgrep] [--bat] [--hub] [--gogh] [--font=ID] [--tig]
#                  [--terminal=NAME]
#
# Can be called by install.sh or run standalone to (re)install individual tools.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/helpers.sh
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
DO_TIG=false
DO_TERMINAL=""

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
    --tig)             DO_TIG=true ;;
    --font=*)
      DO_FONT="${arg#*=}"
      ;;
    --font)
      echo -e "  ${YELLOW}⚠${RESET}  --font requires a value: caskaydia, jetbrains, fira, or hack"
      exit 1
      ;;
    --terminal=*)
      DO_TERMINAL="${arg#*=}"
      ;;
    --terminal)
      echo -e "  ${YELLOW}⚠${RESET}  --terminal requires a value: alacritty, kitty, or wezterm"
      exit 1
      ;;
    --help)
      echo "Usage: $0 [--tmux] [--autosuggestions] [--rbenv] [--nvm] [--fzf] [--ripgrep] [--bat] [--hub] [--gogh] [--font=ID] [--tig] [--terminal=NAME]"
      _bootstrap_spacer
      echo "Font IDs for --font=: caskaydia (default), jetbrains, fira, hack"
      echo "Terminal names for --terminal=: alacritty, kitty, wezterm"
      exit 0
      ;;
    *)
      echo -e "  ${YELLOW}⚠${RESET}  Unknown flag: $arg"
      ;;
  esac
done

if ! $DO_TMUX && ! $DO_AUTOSUGG && ! $DO_RBENV && ! $DO_NVM && ! $DO_FZF && \
   ! $DO_RIPGREP && ! $DO_BAT && ! $DO_HUB && ! $DO_GOGH && ! $DO_TIG && \
   [[ -z "$DO_FONT" ]] && [[ -z "$DO_TERMINAL" ]]; then
  echo -e "${YELLOW}No tools selected. Run with --help to see available flags.${RESET}"
  exit 0
fi

# install.sh drives this per-tool and renders its own progress bar/header, so it
# sets BOOTSTRAP_QUIET=1 to suppress standalone banners, section headings, and
# the footer (must not use `[[ ]] && echo` for the footer — a failed [[ ]]
# would make the script exit 1 and mark every quiet step as failed).
_bootstrap_heading() {
  [[ -z "${BOOTSTRAP_QUIET:-}" ]] && echo -e "${BOLD}→ $1${RESET}"
}
_bootstrap_spacer() {
  [[ -z "${BOOTSTRAP_QUIET:-}" ]] && echo ""
}

if [[ -z "${BOOTSTRAP_QUIET:-}" ]]; then
  echo -e "${CYAN}${BOLD}━━━  Installing tools  ━━━${RESET}"
  _bootstrap_spacer
fi

# ── macOS cask helpers (Gatekeeper / quarantine) ─────────────────────────────
# Homebrew tags downloaded .app bundles with com.apple.quarantine, which triggers
# "Apple could not verify …" on first launch. --no-quarantine avoids the tag;
# clearing it afterward covers older installs and brew versions without the flag.

# Usage: _macos_clear_app_quarantine </path/to/App.app>
_macos_clear_app_quarantine() {
  local app="$1"
  [[ "$OSTYPE" =~ ^darwin ]] || return 0
  [[ -d "$app" ]] || return 0
  if xattr -p com.apple.quarantine "$app" &>/dev/null; then
    xattr -dr com.apple.quarantine "$app"
    echo -e "  ${GREEN}✓${RESET}  Cleared Gatekeeper quarantine on ${BOLD}$(basename "$app")${RESET}"
  fi
}

# Usage: _macos_brew_cask_app_path <cask> [AppName.app]
_macos_brew_cask_app_path() {
  local cask="$1" app_name="${2:-}" path=""

  if [[ -n "$app_name" && -d "/Applications/${app_name}" ]]; then
    echo "/Applications/${app_name}"
    return 0
  fi

  path=$(brew list --cask "$cask" 2>/dev/null | grep '\.app$' | head -1)
  if [[ -n "$path" && -d "$path" ]]; then
    echo "$path"
  fi
}

# Usage: _brew_install_cask <cask> [AppName.app]
_brew_install_cask() {
  local cask="$1" app_name="${2:-}" app=""

  echo -e "  Installing ${BOLD}${cask}${RESET} via Homebrew…"
  if ! brew install --cask --no-quarantine "$cask" 2>/dev/null; then
    brew install --cask "$cask"
  fi

  app=$(_macos_brew_cask_app_path "$cask" "$app_name")
  [[ -n "$app" ]] && _macos_clear_app_quarantine "$app"
}

# Usage: _macos_clear_brew_cask_quarantine <cask> [AppName.app]
_macos_clear_brew_cask_quarantine() {
  local cask="$1" app_name="${2:-}" app=""
  app=$(_macos_brew_cask_app_path "$cask" "$app_name")
  [[ -n "$app" ]] && _macos_clear_app_quarantine "$app"
}

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
  _bootstrap_heading "tmux"
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
  _bootstrap_spacer
fi

# ── zsh-autosuggestions ───────────────────────────────────────────────────────
if $DO_AUTOSUGG; then
  _bootstrap_heading "zsh-autosuggestions"
  if [[ "$OSTYPE" =~ ^darwin ]]; then
    if brew list zsh-autosuggestions &>/dev/null; then
      echo -e "  ${GREEN}✓${RESET}  zsh-autosuggestions already installed — skipping."
    else
      brew install zsh-autosuggestions
    fi
  else
    if [ -d ~/.zsh/zsh-autosuggestions ]; then
      echo -e "  ${GREEN}✓${RESET}  ~/.zsh/zsh-autosuggestions already exists — skipping."
    else
      mkdir -p ~/.zsh
      git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi
  fi
  _bootstrap_spacer
fi

# ── rbenv ─────────────────────────────────────────────────────────────────────
if $DO_RBENV; then
  _bootstrap_heading "rbenv"
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
  _bootstrap_spacer
fi

# ── nvm ───────────────────────────────────────────────────────────────────────
if $DO_NVM; then
  _bootstrap_heading "nvm"
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
  _bootstrap_spacer
fi

# ── FZF ───────────────────────────────────────────────────────────────────────
if $DO_FZF; then
  _bootstrap_heading "FZF"
  if [ -d ~/.fzf ]; then
    echo -e "  ${GREEN}✓${RESET}  ~/.fzf already exists — skipping clone."
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    # Non-interactive: enable key-bindings + completion, but don't touch rc files
    # (this repo's shell/common/fzf.sh already sources ~/.fzf.{bash,zsh}).
    ~/.fzf/install --key-bindings --completion --no-update-rc
  fi
  _bootstrap_spacer
fi

# ── ripgrep ───────────────────────────────────────────────────────────────────
if $DO_RIPGREP; then
  _bootstrap_heading "ripgrep (rg)"
  if command -v rg &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  ripgrep already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install ripgrep
  else
    _linux_install ripgrep
  fi
  _bootstrap_spacer
fi

# ── bat ───────────────────────────────────────────────────────────────────────
if $DO_BAT; then
  _bootstrap_heading "bat"
  if command -v bat &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  bat already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install bat
  else
    _linux_install bat
  fi
  _bootstrap_spacer
fi

# ── hub ───────────────────────────────────────────────────────────────────────
if $DO_HUB; then
  _bootstrap_heading "hub"
  if command -v hub &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  hub already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install hub
  else
    _linux_install hub
  fi
  _bootstrap_spacer
fi

# ── Terminal emulator (install binary if missing) ─────────────────────────────
if [[ -n "$DO_TERMINAL" ]]; then
  case "$DO_TERMINAL" in
    alacritty|kitty|wezterm) ;;
    *)
      echo -e "  ${YELLOW}⚠${RESET}  Unknown terminal: ${BOLD}${DO_TERMINAL}${RESET}"
      echo -e "      Valid names: alacritty, kitty, wezterm"
      exit 1
      ;;
  esac

  _bootstrap_heading "$DO_TERMINAL"
  if command -v "$DO_TERMINAL" &>/dev/null; then
    if [[ "$OSTYPE" =~ ^darwin ]]; then
      case "$DO_TERMINAL" in
        alacritty) _macos_clear_brew_cask_quarantine alacritty "Alacritty.app" ;;
        wezterm)   _macos_clear_brew_cask_quarantine wezterm "WezTerm.app" ;;
      esac
    fi
    echo -e "  ${GREEN}✓${RESET}  ${DO_TERMINAL} already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    case "$DO_TERMINAL" in
      alacritty) _brew_install_cask alacritty "Alacritty.app" ;;
      kitty)     brew install kitty ;;
      wezterm)   _brew_install_cask wezterm "WezTerm.app" ;;
    esac
  elif [[ "$OSTYPE" =~ ^linux ]]; then
    case "$DO_TERMINAL" in
      alacritty) _linux_install alacritty ;;
      kitty)     _linux_install kitty ;;
      wezterm)   _linux_install wezterm ;;
    esac
  else
    echo -e "  ${YELLOW}⚠${RESET}  Unknown OS — please install ${BOLD}${DO_TERMINAL}${RESET} manually."
  fi
  _bootstrap_spacer
fi

# ── Gogh — terminal colour schemes ───────────────────────────────────────────
if $DO_GOGH; then
  _bootstrap_heading "Gogh"
  local_gogh_dir="${GOGH_DIR:-$HOME/src/gogh}"
  if [ -d "$local_gogh_dir" ]; then
    echo -e "  ${GREEN}✓${RESET}  Gogh already cloned at $local_gogh_dir — skipping."
  else
    echo -e "  Cloning Gogh into $local_gogh_dir…"
    git clone --depth 1 https://github.com/Gogh-Co/Gogh "$local_gogh_dir"
    echo -e "  ${GREEN}✓${RESET}  Gogh installed. Run ${BOLD}colorscheme${RESET} in your shell to pick a theme."
  fi
  _bootstrap_spacer
fi

# ── Nerd Font ─────────────────────────────────────────────────────────────────
if [[ -n "$DO_FONT" ]]; then
  # shellcheck source=lib/fonts.sh
  source "$DOTFILES_DIR/lib/fonts.sh"
  _bootstrap_heading "Nerd Font"
  if nerd_font_family "$DO_FONT" &>/dev/null; then
    install_nerd_font "$DO_FONT"
  else
    echo -e "  ${YELLOW}⚠${RESET}  Unknown font ID: ${BOLD}${DO_FONT}${RESET}"
    echo -e "      Valid IDs: caskaydia, jetbrains, fira, hack"
    exit 1
  fi
  _bootstrap_spacer
fi

# ── tig — git text-mode interface ─────────────────────────────────────────────
if $DO_TIG; then
  _bootstrap_heading "tig"
  if command -v tig &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET}  tig already installed — skipping."
  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install tig
  else
    _linux_install tig
  fi
  _bootstrap_spacer
fi

if [[ -z "${BOOTSTRAP_QUIET:-}" ]]; then
  echo -e "${GREEN}${BOLD}Done!${RESET}"
fi
exit 0
