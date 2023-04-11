return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- "help" parser is now shipped with built-in treesitter and removed from nvim-treesitter
      -- Details in https://github.com/LazyVim/LazyVim/issues/524
      opts.ignore_install = { "help" }
    end,
  },
}
