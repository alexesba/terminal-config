local wezterm = require('wezterm')

-- Resolve zsh path at runtime so it works regardless of where it's installed
-- (e.g. /bin/zsh on macOS system, /usr/bin/zsh on Linux, /opt/homebrew/bin/zsh on Apple Silicon)
local function find_shell(name)
  local handle = io.popen('which ' .. name .. ' 2>/dev/null')
  if handle then
    local path = handle:read('*l')
    handle:close()
    if path and path ~= '' then return path end
  end
  return '/bin/' .. name
end

return {
  color_scheme = 'Sonokai (Gogh)',
  default_prog = { find_shell('zsh'), '-l' },
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
