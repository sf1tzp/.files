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
  { "kepano/flexoki-neovim", name = "flexoki" },
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
