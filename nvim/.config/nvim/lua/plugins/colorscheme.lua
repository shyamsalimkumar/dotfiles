-- Flip this to "monokai-pro" and restart Neovim to switch themes.
-- (Or preview either live, without editing this file, via <leader>uC.)
local active_colorscheme = "solarized"

return {
  { "maxmx03/solarized.nvim", lazy = false, priority = 1000, opts = {} },
  { "loctvl842/monokai-pro.nvim", lazy = false, priority = 1000, opts = { filter = "pro" } },
  { "LazyVim/LazyVim", opts = { colorscheme = active_colorscheme } },
}
