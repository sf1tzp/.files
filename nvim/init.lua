--
-- neovim config
--
-- This is a very minimal neovim config which is intended for compatibility with the vscode-neovim extension.
-- Only a few plugins that extend the native set of vim motions are included.
-- See `lua/plugins/mini.lua` for details, keybindings, etc
--
-- IDE tasks such as file opening, splits/window navigation, search and replace, lsp integrations, decoration,
-- etc are handled by vscode.
--
local start_time = vim.loop.hrtime()
-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Unbind some default keybindings
vim.keymap.set({ "n", "x" }, "s", "<Nop>")
vim.keymap.set({ "n", "x" }, "H", "<Nop>")
vim.keymap.set({ "n", "x" }, "J", "<Nop>")
vim.keymap.set({ "n", "x" }, "K", "<Nop>")
vim.keymap.set({ "n", "x" }, "L", "<Nop>")

-- helper to verify config is loaded
vim.keymap.set("n", "<leader>lol", "<cmd>echo 'hello world'<cr>")

-- Table of plugins to import
local plugins = {
	{ import = "plugins.mini" }, -- surround, comment, move, jump motions (vscode compatible)
}

if not vim.g.vscode then
	-- load non-vscode config here
	vim.opt.number = true
	vim.opt.relativenumber = true

	table.insert(plugins, {
		{ import = "plugins.ide" }, -- file explorer, whichkey, telescope, etc
		{ import = "plugins.lsp" }, -- lspconfig, mason,
	})
end

-- Load Plugins
require("config.lazy").setup({ spec = plugins })

-- Calculate elapsed time and display at the end of loading
local end_time = vim.loop.hrtime()
local elapsed = (end_time - start_time) / 1000000 -- Convert nanoseconds to milliseconds
print(string.format("Loaded init.lua in %.2f ms", elapsed))
