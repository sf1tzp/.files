-- Note: LSP Keymaps are defined in lsp.lua

-- Leader key (Start a key sequence)
vim.g.mapleader = " "

-- change default mappings
vim.keymap.set("n", "J", "<nop>") -- disable 'J' (concatenate line down)
vim.keymap.set("n", "<leader>q", "q") -- Use leader key to start recording
vim.keymap.set("n", "<leader>Q", "Q") -- Use leader to play last macro
vim.keymap.set("n", "q", "<nop>") -- disable 'q' (default start recording)
vim.keymap.set("n", "Q", "<nop>") -- disable 'Q' (play last macro)
vim.keymap.set("n", "<C-c>", "<Esc>") -- make ctrl-c quiet
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "<leader>l", ":set relativenumber!<cr>") -- toggle relativenumber

-- Open file right split
-- highlight via telescope or tree and hit ctrl+V
-- Open file down split
-- highlight via telescope or tree and hit ctrl+x
-- Move between splits
-- ctrl+w, hjkl

-- nvim-surround :help nvim-surround.usage

-- nvim comment
--     NORMAL mode
-- `gcc` - Toggles the current line using linewise comment
-- `gbc` - Toggles the current line using blockwise comment
--     VISUAL mode
-- `gc` - Toggles the region using linewise comment
-- `gb` - Toggles the region using blockwise comment

-- Keep cursor centered when jumping
vim.keymap.set("n", "n", "nzzzv") -- slash searching
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- half-page jumping
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<PageUp>", "<PageUp>zz") -- full-page jumping
vim.keymap.set("n", "<PageDown>", "<PageDown>zz")

-- Move selection up and down when in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- paste without overwriting clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])

-- copy to system keyboard
vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("v", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- delete without copying
vim.keymap.set("n", "<leader>d", [["_d]])
vim.keymap.set("v", "<leader>d", [["_d]])

-- Telescope Keymaps
local ts = require("telescope.builtin")
vim.keymap.set("n", "<leader>oo", ts.find_files, {})
vim.keymap.set("n", "<leader>gg", ts.live_grep, {})
vim.keymap.set("n", "<leader>og", ts.git_files, {})

-- treesitter
vim.keymap.set("n", "<leader>@", ":GetCurrentFunctions<cr>")

-- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- fugitive
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

-- minimap
local mm = require('codewindow')
vim.keymap.set("n", "<leader>n", mm.toggle_minimap, {})
vim.keymap.set("n", "<leader>nf", mm.toggle_focus, {})

-- harpoon
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>ha", mark.add_file)
vim.keymap.set("n", "<leader>hr", mark.rm_file)
vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu)

vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end)
vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end)
vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end)
vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end)
vim.keymap.set("n", "<leader>5", function() ui.nav_file(5) end)
vim.keymap.set("n", "<leader>6", function() ui.nav_file(6) end)
vim.keymap.set("n", "<leader>7", function() ui.nav_file(7) end)
vim.keymap.set("n", "<leader>8", function() ui.nav_file(8) end)
vim.keymap.set("n", "<leader>9", function() ui.nav_file(9) end)

