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

-- Open a new session
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

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

-- nvim tree
vim.keymap.set('n', "<leader>tt", vim.cmd.NvimTreeToggle)
vim.keymap.set('n', "<leader>tf", vim.cmd.NvimTreeFocus)

-- Telescope Keymaps
local ts = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", ts.find_files, {})
vim.keymap.set("n", "<leader>fs", ts.live_grep, {})
vim.keymap.set("n", "<leader>fg", ts.git_files, {})

-- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- fugitive
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

