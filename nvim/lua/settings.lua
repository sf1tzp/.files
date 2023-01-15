-- colors
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.cmd([[colorscheme gruvbox]])

-- line options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.signcolumn = "yes" -- display colunm number
vim.opt.colorcolumn = "80" -- highlight column 80
vim.opt.scrolloff = 8 -- keep n lines visible around cursor

-- tabs & indentations
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true -- indent using spaces
vim.opt.autoindent = true
vim.opt.smartindent = true

-- search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true -- use caps in a pattern for case sensitive search
vim.opt.hlsearch = false -- don't highlight every result
vim.opt.incsearch = true -- incremental search

-- backspace behavior
vim.opt.backspace = "indent,eol,start"

-- use system clipboard
vim.opt.clipboard:append("unnamedplus")

-- splits
vim.opt.splitright = true -- :vsplit
vim.opt.splitbelow = true -- :split

-- save & undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

--Set completeopt to have a better completion experience
-- :help completeopt
-- menuone: popup even when there's only one match
-- noinsert: Do not insert text until a selection is made
-- noselect: Do not select, force to select one from the menu
-- shortness: avoid showing extra messages when using completion
-- updatetime: set updatetime for CursorHold
vim.opt.completeopt = {'menuone', 'noselect', 'noinsert'}
vim.opt.shortmess = vim.opt.shortmess + { c = true}
vim.api.nvim_set_option('updatetime', 300)

-- Fixed column for diagnostics to appear
-- Show autodiagnostic popup on cursor hover_range
-- Goto previous / next diagnostic warning / error
-- Show inlay_hints more frequently
vim.cmd([[
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])


-- Add '-' to word symbols
-- opt.iskeyword:append("-")

