local nnoremap = require("steven.keymap").nnoremap

nnoremap("<leader>pv", "<cmd>Ex<CR>")
nnoremap("<leader>tf", "<cmd>Telescope find_files<CR>")
nnoremap("<leader>tg", "<cmd>Telescope live_grep<CR>")
nnoremap("<leader>ff", "<cmd>FzfLua files<CR>")

