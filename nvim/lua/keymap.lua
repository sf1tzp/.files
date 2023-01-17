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
vim.keymap.set("n", "<leader>l", ":set number! norelativenumber<cr>")
-- Open file right split
-- highlight via telescope or tree and hit ctrl+V
-- Open file down split
-- highlight via telescope or tree and hit ctrl+x
-- Move between splits
-- ctrl+w, hjkl

-- nvim-surround
-- The three "core" operations of add/delete/change can be done with the keymaps ys{motion}{char}, ds{char}, and cs{target}{replacement}, respectively. For the following examples, * will denote the cursor position:
--
--     Old text                    Command         New text
-- --------------------------------------------------------------------------------
--     surr*ound_words             ysiw)           (surround_words)
--     *make strings               ys$"            "make strings"
--     [delete ar*ound me!]        ds]             delete around me!
--     remove <b>HTML t*ags</b>    dst             remove HTML tags
--     'change quot*es'            cs'"            "change quotes"
--     <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
--     delete(functi*on calls)     dsf             function calls
--
-- Detailed information on how to use this plugin can be found in :h nvim-surround.usage.

-- nvim comment
--     NORMAL mode
-- `gcc` - Toggles the current line using linewise comment
-- `gbc` - Toggles the current line using blockwise comment
-- `[count]gcc` - Toggles the number of line given as a prefix-count using linewise
-- `[count]gbc` - Toggles the number of line given as a prefix-count using blockwise
-- `gc[count]{motion}` - (Op-pending) Toggles the region using linewise comment
-- `gb[count]{motion}` - (Op-pending) Toggles the region using blockwise comment
-- `gco` - Insert comment to the next line and enters INSERT mode
-- `gcO` - Insert comment to the previous line and enters INSERT mode
-- `gcA` - Insert comment to end of the current line and enters INSERT mode
--     VISUAL mode
-- `gc` - Toggles the region using linewise comment
-- `gb` - Toggles the region using blockwise comment
-- for more, see readme

-- Open a folder as a new session
vim.keymap.set("n", "<C-f>", "<cmd>silent !tms<CR>")

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
vim.keymap.set("n", "<leader>o", ts.find_files, {})
vim.keymap.set("n", "<leader>g", ts.live_grep, {})
vim.keymap.set("n", "<leader>og", ts.git_files, {})

-- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- fugitive
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

-- minimap
local mm = require('codewindow')
vim.keymap.set("n", "<leader>n", mm.toggle_minimap, {})
vim.keymap.set("n", "<leader>nf", mm.toggle_focus, {})

