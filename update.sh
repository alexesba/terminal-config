#!/usr/bin/env bash
# update.sh — pull latest dotfiles and refresh repo-managed symlinks.
#
# Safe to run at any time. Template-based configs (tmux, terminal emulators) are
# copied once into your home directory — update.sh never overwrites those local
# files, so your edits are preserved across git pull.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/helpers.sh
source "$DOTFILES_DIR/lib/helpers.sh"

echo -e "${CYAN}${BOLD}━━━  Updating dotfiles  ━━━${RESET}"
echo ""

# ── Pull latest changes ───────────────────────────────────────────────────────
cd "$DOTFILES_DIR" || exit 1
echo -e "${BOLD}→ git pull${RESET}"
git pull --ff-only
echo ""

# ── Re-link any symlinks already pointing into this repo ─────────────────────
echo -e "${BOLD}→ Refreshing dotfiles${RESET}"
echo -e "   ${DIM}(symlinks only — local template copies are never overwritten)${RESET}"
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

# tmux + terminal emulators — migrate legacy symlinks → local copies (with backup)
install_config_from_template "$DOTFILES_DIR" \
  "tmux.conf.example" "${HOME}/.tmux.conf"
remove_legacy_repo_copy "$DOTFILES_DIR/tmux.conf" "${HOME}/.tmux.conf"

install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/alacritty.yml.example" "${HOME}/.config/alacritty/alacritty.yml"
remove_legacy_repo_copy "$DOTFILES_DIR/terminal-emulators/alacritty.yml" \
  "${HOME}/.config/alacritty/alacritty.yml"
remove_legacy_repo_copy "$DOTFILES_DIR/terminals/alacritty.yml" \
  "${HOME}/.config/alacritty/alacritty.yml"

install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/kitty.conf.example" "${HOME}/.config/kitty/kitty.conf"
remove_legacy_repo_copy "$DOTFILES_DIR/terminal-emulators/kitty.conf" \
  "${HOME}/.config/kitty/kitty.conf"
remove_legacy_repo_copy "$DOTFILES_DIR/terminals/kitty.conf" \
  "${HOME}/.config/kitty/kitty.conf"

install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/wezterm.lua.example" "${HOME}/.config/wezterm/wezterm.lua"
remove_legacy_repo_copy "$DOTFILES_DIR/terminal-emulators/wezterm.lua" \
  "${HOME}/.config/wezterm/wezterm.lua"
remove_legacy_repo_copy "$DOTFILES_DIR/terminals/wezterm.lua" \
  "${HOME}/.config/wezterm/wezterm.lua"

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
echo -e "  ${DIM}Restart your shell or run: source ~/${BASH_SOURCE[0]##*/}${RESET}"
