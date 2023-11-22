return {
  {
    "ntpeters/vim-better-whitespace",
    config = function()
      vim.cmd([[highlight ExtraWhitespace guibg=#bc362a gui=nocombine]])
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      symbol = "▏",
    },
  },
}
