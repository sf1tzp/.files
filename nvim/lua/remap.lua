local nnoremap = require("keymap").nnoremap

vim.g.mapleader = " "

nnoremap("<leader>pv", "<cmd>Ex<CR>")
nnoremap("<leader>tf", "<cmd>Telescope find_files<CR>")
nnoremap("<leader>tg", "<cmd>Telescope live_grep<CR>")
nnoremap("<leader>ff", "<cmd>FzfLua files<CR>")
nnoremap("<leader>gg", "<cmd>FzfLua grep<CR>")

