--
local start_time = vim.loop.hrtime()
-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Unbind some default keybindings
vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'H', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'J', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'K', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'L', '<Nop>')

-- helper to verify config is loaded
vim.keymap.set("n", "<leader>lol", "<cmd>echo 'hello world'<cr>")

if not vim.g.vscode then
    -- put non-vscode exclusive config here
end

-- Load Plugins
-- lazy will load all *.lua files in `lua/plugins/`
require("config.lazy")

-- Calculate elapsed time and print at the end
local end_time = vim.loop.hrtime()
local elapsed = (end_time - start_time) / 1000000 -- Convert nanoseconds to milliseconds
print(string.format("loaded init.lua in %.2f ms", elapsed))
