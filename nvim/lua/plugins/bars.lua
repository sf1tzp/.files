return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    opts = {
      options = {
        separator_style = "padded_slant",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "everforest",
      },
    },
  },
  {
    "SmiteshP/nvim-navic",
    opts = function(_, opts)
      opts.highlight = false
    end,
  },
}
