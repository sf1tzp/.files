vim.opt.background = dark
vim.g.tokyonight_transparent = true

vim.cmd [[
try
  colorscheme gruvbox 
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry
]]

