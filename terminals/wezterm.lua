local wezterm = require('wezterm')

return {
  color_scheme = 'Sonokai (Gogh)',
  -- default_prog is intentionally unset — WezTerm will use $SHELL as a login
  -- shell automatically, which works correctly for any shell (zsh, fish, nushell, etc.)
  font_size = 14.0,
  window_decorations = 'RESIZE',
  enable_tab_bar = false,
  use_fancy_tab_bar = false,
  force_reverse_video_cursor = true,
  freetype_load_flags = 'NO_HINTING',
  font = wezterm.font({
    -- family = 'JetBrainsMonoNL Nerd Font',
    family = 'CaskaydiaCove Nerd Font Propo',
    -- family = 'FiraCode Nerd Font',
    -- family = 'FiraCode Nerd Font Mono',
    -- family = 'Operator Mono Lig',
    -- 'JetBrainsMonoNL',
    -- family = 'Operator Mono',
    -- family = 'JetBrainsMonoNL Nerd Font Propo',
    harfbuzz_features = {"calt=1", "clig=1", "liga=1"},
  })
}
