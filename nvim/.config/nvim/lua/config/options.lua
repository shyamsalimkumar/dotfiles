-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- both configured colorschemes (see lua/plugins/colorscheme.lua) are dark variants
opt.background = "dark"

-- carried over from the old vim-plug config's personal preferences
opt.colorcolumn = "121"
opt.textwidth = 120
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.cpoptions:append("$")
