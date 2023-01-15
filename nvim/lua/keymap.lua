vim.g.mapleader = " "

-- nvim tree
vim.keymap.set('n', "<leader>tt", ":NvimTreeToggle<cr>")
vim.keymap.set('n', "<leader>td", ":NvimTreeFocus<cr>")

-- Telescope Keymaps
local ts = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", ts.find_files, {})
vim.keymap.set("n", "<leader>fs", ts.live_grep, {})
vim.keymap.set("n", "<leader>fg", ts.git_files, {})

