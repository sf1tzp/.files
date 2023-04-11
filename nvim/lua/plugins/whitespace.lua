return {
  "ntpeters/vim-better-whitespace",
  config = function()
    vim.cmd([[highlight ExtraWhitespace guibg=#bc362a gui=nocombine]])
  end,
}
