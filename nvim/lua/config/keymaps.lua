-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>ul", "<cmd>set relativenumber!<cr>") -- toggle relativenumber

-- Move Lines
vim.keymap.set("n", "<A-j>", "")
vim.keymap.set("n", "<A-k>", "")
vim.keymap.set("i", "<A-j>", "")
vim.keymap.set("i", "<A-k>", "")
vim.keymap.set("v", "<A-j>", "")
vim.keymap.set("v", "<A-k>", "")
