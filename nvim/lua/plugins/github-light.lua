return {
  {
    "romgrk/github-light.vim",
    dependencies = {
      "lukas-reineke/indent-blankline.nvim",
    },
    config = function()
      vim.cmd([[highlight IndentBlanklineIndent1 guibg=#323232 gui=nocombine]])
      vim.cmd([[highlight IndentBlanklineIndent2 guibg=#413d3b gui=nocombine]])
    end,
  },
}
