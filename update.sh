#!/usr/bin/env bash
# update.sh — pull latest dotfiles and re-link any existing symlinks.
#
# Safe to run at any time. Only re-links files that are already symlinked
# into this repo — it will not install anything new.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/lib/helpers.sh"

echo -e "${CYAN}${BOLD}━━━  Updating dotfiles  ━━━${RESET}"
echo ""

# ── Pull latest changes ───────────────────────────────────────────────────────
cd "$DOTFILES_DIR" || exit 1
echo -e "${BOLD}→ git pull${RESET}"
git pull --ff-only
echo ""

# ── Re-link any symlinks already pointing into this repo ─────────────────────
echo -e "${BOLD}→ Re-linking dotfiles${RESET}"
echo -e "   ${DIM}(only files already symlinked into $DOTFILES_DIR)${RESET}"
echo ""

_relink_if_mine() {
  local dest="$1"
  local src="$2"
  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$DOTFILES_DIR"* ]]; then
    link_file "$src" "$dest"
  fi
}

# Shell RC — rc.sh (upgrade legacy bash_profile.sh symlinks too)
for _rc in ~/.zshrc ~/.bashrc; do
  if [ -L "$_rc" ]; then
    _target="$(readlink "$_rc")"
    if [[ "$_target" == "$DOTFILES_DIR"* ]]; then
      if [[ "$_target" == *bash_profile.sh ]]; then
        echo -e "  ${YELLOW}⚠${RESET}  Upgrading $_rc: bash_profile.sh → rc.sh"
        link_file "$DOTFILES_DIR/rc.sh" "$_rc"
      else
        _relink_if_mine "$_rc" "$DOTFILES_DIR/rc.sh"
      fi
    fi
  fi
done

# tmux + terminal emulators — copy from templates (migrate legacy symlinks)
install_config_from_template "$DOTFILES_DIR" \
  "tmux.conf.example" "${HOME}/.tmux.conf"
if [ -f "$DOTFILES_DIR/tmux.conf" ] && [ -f "${HOME}/.tmux.conf" ] && [ ! -L "${HOME}/.tmux.conf" ]; then
  rm -f "$DOTFILES_DIR/tmux.conf"
  echo -e "  ${GREEN}✓${RESET}  Removed legacy $DOTFILES_DIR/tmux.conf (now at ~/.tmux.conf)."
fi

install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/alacritty.yml.example" "${HOME}/.config/alacritty/alacritty.yml"
install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/kitty.conf.example" "${HOME}/.config/kitty/kitty.conf"
install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/wezterm.lua.example" "${HOME}/.config/wezterm/wezterm.lua"

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  ${DIM}Restart your shell or run: source ~/${BASH_SOURCE[0]##*/}${RESET}"
