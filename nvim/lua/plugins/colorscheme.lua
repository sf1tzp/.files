return {
  -- add gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      local config = {
        overrides = {
          SignColumn = { bg = "#282828" },
        },
      }
      require("gruvbox").setup(config)
    end,
  },
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
    lazy = false,
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
  },
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
  },
  { "projekt0n/github-nvim-theme" },
  { "rebelot/kanagawa.nvim" },
  { "Shatur/neovim-ayu" },
  { "sainnhe/everforest" },
  { "loctvl842/monokai-pro.nvim" },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "savq/melange-nvim" },
  { "AlexvZyl/nordic.nvim" },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
