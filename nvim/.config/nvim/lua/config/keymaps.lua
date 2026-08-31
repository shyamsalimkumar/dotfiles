-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- quickfix navigation, paired with the sarsi-nvim integration in autocmds.lua
-- (<leader>l/f/g are already claimed by LazyVim's Lazy/find/git groups, so this
-- gets its own prefix instead of shadowing them)
vim.keymap.set("n", "<leader>Qf", "<cmd>cfirst<cr>", { desc = "Quickfix: First" })
vim.keymap.set("n", "<leader>Qn", "<cmd>cnext<cr>", { desc = "Quickfix: Next" })
vim.keymap.set("n", "<leader>Qp", "<cmd>cprevious<cr>", { desc = "Quickfix: Previous" })
