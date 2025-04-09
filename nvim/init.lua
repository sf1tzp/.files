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
vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'S', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'H', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'J', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'K', '<Nop>')
vim.keymap.set({ 'n', 'x' }, 'L', '<Nop>')

-- Rebind Macro Record / Playback
vim.keymap.set('n', 'q', '<Nop>', { noremap = true })
vim.keymap.set('n', 'Q', '<Nop>', { noremap = true })
vim.keymap.set('n', '<leader>R', 'q', { noremap = true, desc = 'Record macro' })
vim.keymap.set('n', '<leader>P', 'Q', { noremap = true, desc = 'Play macro' })

-- helper to verify config is loaded
vim.keymap.set("n", "<leader>lol", "<cmd>echo 'hello world'<cr>")

-- Initialize Lazy Plugin Manager
require("config.lazy")

-- Plugins to load all the time
local plugins = {
  { import = "plugins/mini" }
}

if not vim.g.vscode then -- load other plugins when not running in the vscode extension
  plugins[#plugins + 1] = { import = "plugins/tmux-navigator" }
  plugins[#plugins + 1] = { import = "plugins/treesitter" }
  plugins[#plugins + 1] = { import = "plugins/telescope" }
  plugins[#plugins + 1] = { import = "plugins/git" }
  plugins[#plugins + 1] = { import = "plugins/dashboard" }
  plugins[#plugins + 1] = { import = "plugins/oil" }
  plugins[#plugins + 1] = { import = "plugins/whichkey" }
  vim.opt.relativenumber = true
end

require("config.options")()

-- Setup lazy.nvim
require("lazy").setup({
  spec = plugins,
  -- automatically check for plugin updates
  checker = { enabled = false },
})

-- Calculate elapsed time and display at the end of loading
local end_time = vim.loop.hrtime()
local elapsed = (end_time - start_time) / 1000000 -- Convert nanoseconds to milliseconds
print(string.format("Loaded init.lua in %.2f ms", elapsed))

