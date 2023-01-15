vim.g.mapleader = " "

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

