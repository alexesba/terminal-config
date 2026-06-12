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

migrate_local_sh "$DOTFILES_DIR"

# ── Pull latest changes ───────────────────────────────────────────────────────
cd "$DOTFILES_DIR" || exit 1
echo -e "${BOLD}→ git pull${RESET}"
git pull --ff-only
echo ""

# ── Re-link any symlinks already pointing into this repo ─────────────────────
echo -e "${BOLD}→ Refreshing dotfiles${RESET}"
echo -e "   ${DIM}(managed wrappers and symlinks — local template copies are never overwritten)${RESET}"
echo ""

_refresh_shell_rc() {
  local dest="$1"
  if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$DOTFILES_DIR"* ]]; then
    install_shell_rc_wrapper "$DOTFILES_DIR/rc.sh" "$dest"
  elif [ -f "$dest" ] && grep -qF '# terminal-config: begin' "$dest"; then
    install_shell_rc_wrapper "$DOTFILES_DIR/rc.sh" "$dest"
  fi
}

# Shell RC — local wrapper sourcing rc.sh
for _rc in ~/.zshrc ~/.bashrc; do
  _refresh_shell_rc "$_rc"
done

# tmux + terminal emulators — migrate legacy symlinks → local copies (with backup)
install_config_from_template "$DOTFILES_DIR" \
  "tmux.conf.example" "${HOME}/.tmux.conf"
mkdir -p "${HOME}/.tmux"
install -m 755 "$DOTFILES_DIR/lib/tmux-activity-spinner.sh" "${HOME}/.tmux/activity-spinner.sh"
install -m 755 "$DOTFILES_DIR/lib/tmux-clear-resurrect-when-empty.sh" "${HOME}/.tmux/clear-resurrect-when-empty.sh"
remove_legacy_repo_copy "$DOTFILES_DIR/tmux.conf" "${HOME}/.tmux.conf"

migrate_alacritty_yaml_config
install_config_from_template "$DOTFILES_DIR" \
  "terminal-emulators/alacritty.toml.example" "${HOME}/.config/alacritty/alacritty.toml"
remove_legacy_repo_copy "$DOTFILES_DIR/terminal-emulators/alacritty.yml" \
  "${HOME}/.config/alacritty/alacritty.yml"
remove_legacy_repo_copy "$DOTFILES_DIR/terminal-emulators/alacritty.toml" \
  "${HOME}/.config/alacritty/alacritty.toml"
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

if [ -t 0 ]; then
  ask_yn "Reload shell now?"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
      echo -e "  Reloading shell…"
      reload_interactive_shell
    else
      echo -e "  Run ${BOLD}reload${RESET} in your shell to pick up changes."
      echo -e "  ${DIM}(./update.sh runs in a subshell — use reload in your interactive session.)${RESET}"
    fi
  fi
  echo -e "  ${DIM}Or open a new terminal tab.${RESET}"
else
  echo -e "  ${DIM}Run ${BOLD}reload${RESET} or open a new terminal tab.${RESET}"
fi
