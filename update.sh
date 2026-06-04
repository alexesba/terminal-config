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

# tmux — ensure local tmux.conf exists, then re-link (upgrade legacy symlink to example)
if [ ! -f "$DOTFILES_DIR/tmux.conf" ] && [ -f "$DOTFILES_DIR/tmux.conf.example" ]; then
  if [ -L ~/.tmux.conf ] && [[ "$(readlink ~/.tmux.conf)" == "$DOTFILES_DIR/tmux.conf.example" ]]; then
    cp "$DOTFILES_DIR/tmux.conf.example" "$DOTFILES_DIR/tmux.conf"
    echo -e "  ${GREEN}✓${RESET}  Created tmux.conf from template (was linked to example only)."
  elif [ -L ~/.tmux.conf ] && [[ "$(readlink ~/.tmux.conf)" == "$DOTFILES_DIR"* ]]; then
    cp "$DOTFILES_DIR/tmux.conf.example" "$DOTFILES_DIR/tmux.conf"
    echo -e "  ${GREEN}✓${RESET}  Created tmux.conf from template."
  fi
fi
_relink_if_mine ~/.tmux.conf "$DOTFILES_DIR/tmux.conf"
_relink_if_mine ~/.config/alacritty/alacritty.yml "$DOTFILES_DIR/terminal-emulators/alacritty.yml"
_relink_if_mine ~/.config/kitty/kitty.conf        "$DOTFILES_DIR/terminal-emulators/kitty.conf"
install_wezterm_config "$DOTFILES_DIR"

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  ${DIM}Restart your shell or run: source ~/${BASH_SOURCE[0]##*/}${RESET}"
