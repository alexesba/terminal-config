#!/usr/bin/env bash

# Resolve the directory where this script lives, regardless of where it's called from
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/helpers.sh
source "$DOTFILES_DIR/lib/helpers.sh"
# shellcheck source=lib/fonts.sh
source "$DOTFILES_DIR/lib/fonts.sh"
# shellcheck source=lib/tui.sh
source "$DOTFILES_DIR/lib/tui.sh"

LOCAL_FILE="$(local_sh_path)"
migrate_local_sh "$DOTFILES_DIR"

printf "${CYAN}${BOLD}"
cat << "EOF"
  _                      _             _                    __ _
 | |_ ___ _ __ _ __ ___ (_)_ __   __ _| |   ___ ___  _ __  / _(_) __ _
 | __/ _ \ '__| '_ ` _ \| | '_ \ / _` | |  / __/ _ \| '_ \| |_| |/ _` |
 | ||  __/ |  | | | | | | | | | | (_| | | | (_| (_) | | | |  _| | (_| |
  \__\___|_|  |_| |_| |_|_|_| |_|\__,_|_|  \___\___/|_| |_|_| |_|\__, |
                                                                 |___/
EOF
printf "${RESET}\n"
echo -e "${DIM}        shell · terminal emulators · tools${RESET}"

echo -e "${DIM}Installing from: $DOTFILES_DIR${RESET}"
echo ""
echo -e "${CYAN}${BOLD}Let's set up your shell, terminal, and tools. Answer a few questions first:${RESET}"
echo ""

# Ask a yes/no question that collapses to a one-line summary once answered.
# Usage: q_yn <result_var> <number> <title> <prompt> [desc line...]
q_yn() {
  local __var="$1" num="$2" title="$3" prompt="$4"; shift 4
  local line val
  tui_begin
  echo -e "${BOLD}${num}. ${title}${RESET}"
  for line in "$@"; do echo -e "   ${DIM}${line}${RESET}"; done
  ask_yn "$prompt"
  printf -v "$__var" '%s' "$REPLY"
  [[ $REPLY =~ ^[Yy]$ ]] && val="yes" || val="${DIM}skip${RESET}"
  tui_collapse "$num. $title" "$val"
}

# Like q_yn, but auto-skips when the shell RC wrapper step was declined — those
# options only take effect when rc.sh is sourced from ~/{.zshrc,.bashrc}.
# Usage: q_yn_if_shell <result_var> <number> <title> <prompt> [desc line...]
q_yn_if_shell() {
  local __var="$1" num="$2" title="$3" prompt="$4"; shift 4
  if [[ ! $INSTALL_SHELL =~ ^[Yy]$ ]]; then
    printf -v "$__var" 'n'
    tui_collapse "$num. $title" "${DIM}skip (needs ${HOME}/$BASHFILE → rc.sh)${RESET}"
    return
  fi
  q_yn "$__var" "$num" "$title" "$prompt" "$@"
}

# Auto-skip when FZF was declined — ripgrep/bat only wire into FZF in rc.sh;
# Gogh's colorscheme picker also invokes fzf directly.
# Usage: q_yn_if_fzf <result_var> <number> <title> <prompt> [desc line...]
q_yn_if_fzf() {
  local __var="$1" num="$2" title="$3" prompt="$4"; shift 4
  if [[ ! $INSTALL_FZF =~ ^[Yy]$ ]]; then
    printf -v "$__var" 'n'
    tui_collapse "$num. $title" "${DIM}skip (needs FZF)${RESET}"
    return
  fi
  q_yn "$__var" "$num" "$title" "$prompt" "$@"
}

# Like q_yn_if_shell, but also requires FZF (colorscheme function + fzf picker).
# Usage: q_yn_if_shell_and_fzf <result_var> <number> <title> <prompt> [desc...]
q_yn_if_shell_and_fzf() {
  local __var="$1" num="$2" title="$3" prompt="$4"; shift 4
  if [[ ! $INSTALL_SHELL =~ ^[Yy]$ ]]; then
    printf -v "$__var" 'n'
    tui_collapse "$num. $title" "${DIM}skip (needs ${HOME}/$BASHFILE → rc.sh)${RESET}"
    return
  fi
  if [[ ! $INSTALL_FZF =~ ^[Yy]$ ]]; then
    printf -v "$__var" 'n'
    tui_collapse "$num. $title" "${DIM}skip (needs FZF)${RESET}"
    return
  fi
  q_yn "$__var" "$num" "$title" "$prompt" "$@"
}

# ── 1. Shell ──────────────────────────────────────────────────────────────────
_detected_shell_name=""
if [[ "$SHELL" =~ zsh ]];  then _detected_shell_name="zsh"
elif [[ "$SHELL" =~ bash ]]; then _detected_shell_name="bash"
fi

_pick_shell() {
  echo    "   Which shell would you like to configure?"
  echo -e "     ${BOLD}1)${RESET} zsh   ${DIM}→ ~/.zshrc${RESET}"
  echo -e "     ${BOLD}2)${RESET} bash  ${DIM}→ ~/.bashrc${RESET}"
  ask_choice "Shell" 2
  if [[ $REPLY == "1" ]]; then
    TEM_SHELL=$(command -v zsh); BASHFILE=".zshrc"
  else
    TEM_SHELL=$(command -v bash); BASHFILE=".bashrc"
  fi
}

tui_begin
echo -e "${BOLD}1. Shell${RESET}"
if [[ -n "$_detected_shell_name" ]]; then
  echo -e "   ${DIM}Default shell detected:${RESET} ${BOLD}${_detected_shell_name}${RESET} ${DIM}(${SHELL})${RESET}"
  ask_yn "Configure for ${_detected_shell_name}?"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    TEM_SHELL="$SHELL"
    BASHFILE="$([[ "$_detected_shell_name" == "zsh" ]] && echo ".zshrc" || echo ".bashrc")"
  else
    _pick_shell
  fi
else
  echo -e "   ${YELLOW}⚠${RESET}  Could not detect default shell from \$SHELL."
  _pick_shell
fi

# Offer chsh if the chosen shell differs from the current default
if [[ -n "$TEM_SHELL" && "$TEM_SHELL" != "$SHELL" ]]; then
  echo -e "   ${DIM}Current default login shell: $SHELL${RESET}"
  ask_yn "Set $(basename "$TEM_SHELL") as your default login shell? (runs chsh)"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    chsh -s "$TEM_SHELL"
    echo -e "  ${GREEN}✓${RESET}  Default login shell set to $TEM_SHELL — re-login to take effect."
  fi
fi

echo -e "   ${DIM}Installs ${HOME}/$BASHFILE wrapper sourcing rc.sh${RESET}"
echo    "   Provides aliases and prompt settings."
ask_yn "Install ${HOME}/$BASHFILE?"
INSTALL_SHELL=$REPLY
if [[ $INSTALL_SHELL =~ ^[Yy]$ ]]; then
  tui_collapse "1. Shell" "${BASHFILE#.} → ${HOME}/$BASHFILE wrapper"
else
  tui_collapse "1. Shell" "${BASHFILE#.} ${DIM}(wrapper: skip)${RESET}"
fi

# ── 2-3. Simple yes/no steps ──────────────────────────────────────────────────
q_yn INSTALL_TMUX 2 "tmux (.tmux.conf)" "Install?" \
  "Copies tmux.conf.example → ~/.tmux.conf" \
  "Custom keybindings, status bar, and plugin settings." \
  "tmux binary will be installed if not already present."

q_yn_if_shell INSTALL_ALIASES 3 "Local alias overrides (~/.bash_aliases)" "Create empty ~/.bash_aliases?" \
  "Built-in aliases load automatically from the repo (shell/aliases/)." \
  "Optionally create ~/.bash_aliases for machine-specific extras (not symlinked)."

q_yn_if_shell INSTALL_NVIM_EDITOR 4 "Default editor (nvim)" "Set EDITOR=nvim?" \
  "Writes export EDITOR=nvim to ~/.local.sh." \
  "Used by git, the Ctrl-O/Ctrl-F file opener, and other CLI tools."

# ── 5. Terminal emulator + font ───────────────────────────────────────────────
INSTALL_WSL_TERMINAL=0
_wsl_detected_terms=""
tui_begin
echo -e "${BOLD}5. Terminal emulator config${RESET}"
if is_wsl; then
  echo -e "   ${YELLOW}⚠${RESET}  WSL detected — terminal emulators run on the Windows side."
  INSTALL_TERMINAL=4
  wsl_wezterm_detected_p && _wsl_detected_terms="${_wsl_detected_terms}wezterm "
  wsl_kitty_detected_p && _wsl_detected_terms="${_wsl_detected_terms}kitty "
  wsl_alacritty_detected_p && _wsl_detected_terms="${_wsl_detected_terms}alacritty "
  if [ -n "$_wsl_detected_terms" ]; then
    INSTALL_WSL_TERMINAL=1
    echo -e "   ${GREEN}✓${RESET}  Detected on Windows:${RESET} ${BOLD}${_wsl_detected_terms}${RESET}"
    echo -e "   ${DIM}install will set ~/.local.sh paths and copy missing config templates.${RESET}"
  else
    echo -e "   ${DIM}No WezTerm, Kitty, or Alacritty detected. Install one on Windows, then re-run install.${RESET}"
  fi
else
  _saved_terminal=""
  [ -f "$LOCAL_FILE" ] && _saved_terminal=$(custom_export_value "$LOCAL_FILE" TERMINAL)
  _terminal_default=""
  case "$_saved_terminal" in
    alacritty) _terminal_default=1 ;;
    kitty)     _terminal_default=2 ;;
    wezterm)   _terminal_default=3 ;;
  esac

  echo    "   Pick a terminal (or skip):"
  echo -e "     ${BOLD}1)${RESET} Alacritty  ${DIM}→ installs if missing + copies template to ~/.config/alacritty/alacritty.toml${RESET}"
  echo -e "     ${BOLD}2)${RESET} Kitty      ${DIM}→ installs if missing + copies template to ~/.config/kitty/kitty.conf${RESET}"
  echo -e "     ${BOLD}3)${RESET} WezTerm    ${DIM}→ installs if missing + copies template to ~/.config/wezterm/wezterm.lua${RESET}"
  echo -e "     ${BOLD}4)${RESET} Skip"
  if [[ -n "$_saved_terminal" && -n "$_terminal_default" ]]; then
    echo -e "   ${DIM}Current selection:${RESET} ${BOLD}${_saved_terminal}${RESET} ${DIM}(Enter keeps it; 4 also preserves it)${RESET}"
  elif [[ -n "$_saved_terminal" ]]; then
    echo -e "   ${DIM}Current selection:${RESET} ${BOLD}${_saved_terminal}${RESET}"
    if is_colorscheme_terminal "$_saved_terminal"; then
      echo -e "   ${DIM}No template shipped for it, but colorscheme can theme it — pick 4 to keep it.${RESET}"
    else
      echo -e "   ${YELLOW}⚠${RESET}  ${BOLD}${_saved_terminal}${RESET} is not compatible with the ${BOLD}colorscheme${RESET} function"
      echo -e "      ${DIM}(gogh supports alacritty, kitty, wezterm, gnome-terminal, konsole, foot, …).${RESET}"
      echo -e "      ${DIM}Pick 1-3 to switch, or 4 to keep it.${RESET}"
    fi
  fi
  ask_choice "Choice" 4 "$_terminal_default"
  INSTALL_TERMINAL=$REPLY
fi

TERMINAL_NAME=""
TERMINAL_FONT_ID=""
TERMINAL_FONT_FAMILY=""
INSTALL_FONT=false
case "$INSTALL_TERMINAL" in
  1) TERMINAL_NAME="alacritty" ;;
  2) TERMINAL_NAME="kitty" ;;
  3) TERMINAL_NAME="wezterm" ;;
esac

if [[ "$INSTALL_TERMINAL" =~ ^[123]$ ]]; then
  _saved_font_id=""
  [ -f "$LOCAL_FILE" ] && _saved_font_id=$(resolve_nerd_font_id "$LOCAL_FILE")
  case "$_saved_font_id" in
    jetbrains) _font_default=2 ;;
    fira)      _font_default=3 ;;
    hack)      _font_default=4 ;;
    *)         _font_default=1 ;;
  esac

  echo    "   Nerd Font for your terminal config:"
  echo -e "     ${BOLD}1)${RESET} Caskaydia Cove Nerd Font Propo"
  echo -e "     ${BOLD}2)${RESET} JetBrains Mono Nerd Font"
  echo -e "     ${BOLD}3)${RESET} FiraCode Nerd Font"
  echo -e "     ${BOLD}4)${RESET} Hack Nerd Font Mono"
  echo -e "     ${BOLD}5)${RESET} Skip font install (config still uses the default font)"
  ask_choice "Font" 5 "$_font_default"
  INSTALL_FONT=true
  case "$REPLY" in
    2) TERMINAL_FONT_ID="jetbrains" ;;
    3) TERMINAL_FONT_ID="fira" ;;
    4) TERMINAL_FONT_ID="hack" ;;
    5) TERMINAL_FONT_ID="caskaydia"; INSTALL_FONT=false ;;
    *) TERMINAL_FONT_ID="caskaydia" ;;
  esac
  TERMINAL_FONT_FAMILY=$(nerd_font_family "$TERMINAL_FONT_ID")
fi

if [[ "$INSTALL_TERMINAL" =~ ^[123]$ ]]; then
  if [[ "$INSTALL_FONT" == true ]]; then
    tui_collapse "5. Terminal" "${TERMINAL_NAME} + ${TERMINAL_FONT_FAMILY}"
  else
    tui_collapse "5. Terminal" "${TERMINAL_NAME} ${DIM}(font: skip)${RESET}"
  fi
elif [[ "$INSTALL_WSL_TERMINAL" == 1 ]]; then
  tui_collapse "5. Terminal" "Windows: ${_wsl_detected_terms% }"
else
  tui_collapse "5. Terminal" "${DIM}skip${RESET}"
fi

# ── 6-14. Tool steps ──────────────────────────────────────────────────────────
q_yn_if_shell INSTALL_AUTOSUGG 6 "zsh-autosuggestions" "Install?" \
  "Installed via brew (or cloned to ~/.zsh/zsh-autosuggestions)." \
  "Suggests commands as you type based on your history."

q_yn_if_shell INSTALL_RBENV 7 "rbenv — Ruby version manager" "Install?" \
  "Installed via brew (macOS) or git clone on Linux." \
  "Manages multiple Ruby versions per project via .ruby-version."

q_yn_if_shell INSTALL_NVM 8 "nvm — Node version manager" "Install?" \
  "Installed via the official nvm install script (latest version)." \
  "Switches Node versions automatically based on .nvmrc files."

q_yn_if_shell INSTALL_FZF 9 "FZF — fuzzy finder" "Install?" \
  "Clones FZF into ~/.fzf and runs its installer." \
  "Ctrl-T history/files, Ctrl-O/Ctrl-F file finder, and colorscheme picker."

q_yn_if_fzf INSTALL_RIPGREP 10 "ripgrep — fast file search" "Install?" \
  "Lists files for FZF (Ctrl-T, Ctrl-O, Ctrl-F) via FZF_DEFAULT_COMMAND." \
  "Falls back to find/ag when rg is not installed."

q_yn_if_fzf INSTALL_BAT 11 "bat — better cat" "Install?" \
  "Syntax-highlighted previews in FZF (Ctrl-T, Ctrl-O, Ctrl-F)." \
  "Falls back to head when bat is not installed."

q_yn INSTALL_HUB 12 "hub — GitHub CLI wrapper" "Install?" \
  "Wraps git with GitHub-aware commands (alias git=hub)." \
  "Enables: hub pull-request, hub browse, hub clone owner/repo, etc."

q_yn_if_shell_and_fzf INSTALL_GOGH 13 "Gogh — terminal colour schemes" "Install?" \
  "Clones https://github.com/Gogh-Co/Gogh into ~/src/gogh." \
  "Run colorscheme in your shell to fuzzy-pick and apply any scheme." \
  "Requires shell RC (colorscheme function) and FZF (theme picker)."

q_yn INSTALL_TIG 14 "tig — git text-mode interface" "Install?" \
  "Installed via brew (macOS) or your Linux package manager." \
  "Browse commits, branches, and diffs from the terminal."

# ── Bootstrap flags (tool binaries handled by bootstrap.sh) ────────────────────
BOOTSTRAP_FLAGS=()
[[ $INSTALL_TMUX     =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--tmux)
[[ $INSTALL_AUTOSUGG =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--autosuggestions)
[[ $INSTALL_RBENV    =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--rbenv)
[[ $INSTALL_NVM      =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--nvm)
[[ $INSTALL_FZF      =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--fzf)
[[ $INSTALL_RIPGREP  =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--ripgrep)
[[ $INSTALL_BAT      =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--bat)
[[ $INSTALL_HUB      =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--hub)
[[ $INSTALL_GOGH     =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--gogh)
[[ $INSTALL_TIG      =~ ^[Yy]$ ]] && BOOTSTRAP_FLAGS+=(--tig)

bootstrap_label() {
  case "$1" in
    --tmux)            echo "tmux" ;;
    --autosuggestions) echo "zsh-autosuggestions" ;;
    --rbenv)           echo "rbenv" ;;
    --nvm)             echo "nvm" ;;
    --fzf)             echo "fzf" ;;
    --ripgrep)         echo "ripgrep" ;;
    --bat)             echo "bat" ;;
    --hub)             echo "hub" ;;
    --gogh)            echo "gogh" ;;
    --tig)             echo "tig" ;;
    --terminal=*)      echo "terminal (${1#--terminal=})" ;;
    *)                 echo "${1#--}" ;;
  esac
}

# ── Pre-flight summary ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}━━━  Summary — here's what will happen  ━━━${RESET}"
echo ""

_sum() { echo -e "  ${BOLD}$(printf '%-12s' "$1")${RESET} ${2}"; }
_yn()  { [[ $1 =~ ^[Yy]$ ]] && echo "yes" || echo -e "${DIM}skip${RESET}"; }

if [[ $INSTALL_SHELL =~ ^[Yy]$ ]]; then
  _sum "Shell" "${HOME}/$BASHFILE wrapper → rc.sh"
else
  _sum "Shell" "${DIM}skip${RESET}"
  echo ""
  echo -e "  ${YELLOW}⚠${RESET}  Without ${HOME}/$BASHFILE sourcing rc.sh, dotfiles will not load:"
  echo -e "     ${DIM}aliases, colorscheme, FZF keybindings, nvm/rbenv init, zsh-autosuggestions${RESET}"
  echo -e "  ${DIM}Steps that depend on the shell RC were skipped automatically.${RESET}"
fi
_sum "Aliases" "$(_yn "$INSTALL_ALIASES")"
_sum "Editor" "$(_yn "$INSTALL_NVIM_EDITOR")"
if [[ "$INSTALL_TERMINAL" =~ ^[123]$ ]]; then
  if [[ "$INSTALL_FONT" == true ]]; then
    _sum "Terminal" "${TERMINAL_NAME} (install if missing) + config + ${TERMINAL_FONT_FAMILY}"
  else
    _sum "Terminal" "${TERMINAL_NAME} (install if missing) + config (font: skip)"
  fi
elif [[ "$INSTALL_WSL_TERMINAL" == 1 ]]; then
  _sum "Terminal" "Windows: ${_wsl_detected_terms% } → ~/.local.sh + templates"
else
  _sum "Terminal" "${DIM}skip${RESET}"
fi

if [ ${#BOOTSTRAP_FLAGS[@]} -gt 0 ]; then
  _tools=""
  for flag in "${BOOTSTRAP_FLAGS[@]}"; do _tools+="$(bootstrap_label "$flag"), "; done
  _sum "Tools" "${_tools%, }"
else
  _sum "Tools" "${DIM}none${RESET}"
fi
echo ""

ask_yn "Proceed with installation?"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "  ${YELLOW}Aborted — nothing was changed.${RESET}"
  exit 0
fi
echo ""

# ── Execution steps ───────────────────────────────────────────────────────────
_ensure_local_file() {
  if [ ! -f "$LOCAL_FILE" ] && [ -f "$DOTFILES_DIR/shell/local.sh.example" ]; then
    cp "$DOTFILES_DIR/shell/local.sh.example" "$LOCAL_FILE"
  fi
}

step_shell_rc() { install_shell_rc_wrapper "$DOTFILES_DIR/rc.sh" "$HOME/$BASHFILE"; }
step_nvim_editor() {
  _ensure_local_file
  set_env_var "$LOCAL_FILE" EDITOR "nvim"
}
step_tmux_cfg() {
  install_config_from_template "$DOTFILES_DIR" "tmux.conf.example" "${HOME}/.tmux.conf"
  mkdir -p "${HOME}/.tmux"
  install -m 755 "$DOTFILES_DIR/lib/tmux-activity-spinner.sh" "${HOME}/.tmux/activity-spinner.sh"
  install -m 755 "$DOTFILES_DIR/lib/tmux-clear-resurrect-when-empty.sh" "${HOME}/.tmux/clear-resurrect-when-empty.sh"
}
step_aliases()   {
  if [ -e "$HOME/.bash_aliases" ]; then
    echo -e "  ${GREEN}✓${RESET}  ~/.bash_aliases already exists — skipping."
  else
    touch "$HOME/.bash_aliases"
    echo -e "  ${GREEN}✓${RESET}  Created empty ~/.bash_aliases."
  fi
}
step_font()      { install_nerd_font "$TERMINAL_FONT_ID"; }
step_terminal()  {
  case "$INSTALL_TERMINAL" in
    1)
      migrate_alacritty_yaml_config "$(nerd_font_family_for_terminal "$TERMINAL_FONT_ID" alacritty)"
      install_config_from_template "$DOTFILES_DIR" \
        "terminal-emulators/alacritty.toml.example" \
        "${HOME}/.config/alacritty/alacritty.toml" \
        "$(nerd_font_family_for_terminal "$TERMINAL_FONT_ID" alacritty)" ;;
    2)
      install_config_from_template "$DOTFILES_DIR" \
        "terminal-emulators/kitty.conf.example" \
        "${HOME}/.config/kitty/kitty.conf" \
        "$(nerd_font_family_for_terminal "$TERMINAL_FONT_ID" kitty)" ;;
    3)
      install_config_from_template "$DOTFILES_DIR" \
        "terminal-emulators/wezterm.lua.example" \
        "${HOME}/.config/wezterm/wezterm.lua" \
        "$(nerd_font_family_for_terminal "$TERMINAL_FONT_ID" wezterm)" ;;
  esac
  _ensure_local_file
  set_env_var "$LOCAL_FILE" TERMINAL "$TERMINAL_NAME"
  set_env_var "$LOCAL_FILE" TERMINAL_FONT "$TERMINAL_FONT_FAMILY"
  set_env_var "$LOCAL_FILE" TERMINAL_FONT_ID "$TERMINAL_FONT_ID"
}
step_wsl_terminals() {
  _ensure_local_file
  configure_wsl_terminals_local_sh "$LOCAL_FILE"
  install_wsl_terminal_configs "$DOTFILES_DIR" \
    "$(nerd_font_family_for_terminal caskaydia wezterm)"
}
run_bootstrap_flag() { BOOTSTRAP_QUIET=1 bash "$DOTFILES_DIR/bootstrap.sh" "$1"; }

STEP_LABELS=(); STEP_FUNCS=(); STEP_ARGS=()
add_step() { STEP_LABELS+=("$1"); STEP_FUNCS+=("$2"); STEP_ARGS+=("${3:-}"); }

[[ $INSTALL_SHELL   =~ ^[Yy]$ ]] && add_step "Shell RC (${HOME}/$BASHFILE)" step_shell_rc
[[ $INSTALL_NVIM_EDITOR =~ ^[Yy]$ ]] && add_step "Default editor (nvim)" step_nvim_editor
[[ $INSTALL_TMUX    =~ ^[Yy]$ ]] && add_step "tmux config" step_tmux_cfg
[[ $INSTALL_ALIASES =~ ^[Yy]$ ]] && add_step "Local aliases" step_aliases
if [[ "$INSTALL_TERMINAL" =~ ^[123]$ ]]; then
  add_step "Terminal app (${TERMINAL_NAME})" run_bootstrap_flag "--terminal=${TERMINAL_NAME}"
  [[ "$INSTALL_FONT" == true ]] && add_step "Nerd Font (${TERMINAL_FONT_ID})" step_font
  add_step "Terminal config (${TERMINAL_NAME})" step_terminal
elif [[ "$INSTALL_WSL_TERMINAL" == 1 ]]; then
  add_step "Terminals (WSL → Windows)" step_wsl_terminals
fi
for flag in "${BOOTSTRAP_FLAGS[@]}"; do
  add_step "$(bootstrap_label "$flag")" run_bootstrap_flag "$flag"
done

echo -e "${CYAN}${BOLD}━━━  Installing  ━━━${RESET}"
echo ""

TOTAL_STEPS=${#STEP_FUNCS[@]}
if (( TOTAL_STEPS == 0 )); then
  echo -e "  ${DIM}Nothing selected to install.${RESET}"
else
  FAILED=()
  for i in "${!STEP_FUNCS[@]}"; do
    _step_log="$(mktemp "${TMPDIR:-/tmp}/install-step.XXXXXX")"
    _step_lines=0
    _step_status=0

    tui_step_begin "$((i + 1))" "$TOTAL_STEPS" "${STEP_LABELS[$i]}"
    "${STEP_FUNCS[$i]}" "${STEP_ARGS[$i]}" 2>&1 | tee "$_step_log"
    _step_status=${PIPESTATUS[0]}
    _step_lines=$(wc -l < "$_step_log" | tr -d ' ')
    rm -f "$_step_log"

    if (( _step_status != 0 )); then
      FAILED+=("${STEP_LABELS[$i]}")
    fi
    tui_step_end "$((i + 1))" "$TOTAL_STEPS" "${STEP_LABELS[$i]}" "$_step_lines" "$_step_status"
  done
  if (( ${#FAILED[@]} > 0 )); then
    echo ""
    echo -e "  ${YELLOW}⚠${RESET}  Some steps reported errors: ${BOLD}${FAILED[*]}${RESET}"
  fi
fi

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  Reloading shell…"
exec "$SHELL" -l
