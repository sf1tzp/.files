return {
  {
    "numToStr/Navigator.nvim",
    lazy = true,
    config = function()
      require("Navigator").setup({
        auto_save = "current",
      })
    end,
    keys = {
      { "<C-h>", "<CMD>NavigatorLeft<CR>", desc = "Move to the left pane" },
      { "<C-j>", "<CMD>NavigatorDown<CR>", desc = "Move to the lower pane" },
      { "<C-k>", "<CMD>NavigatorUp<CR>", desc = "Move to the upper pane" },
      { "<C-l>", "<CMD>NavigatorRight<CR>", desc = "Move to the right pane" },
    },
  },
}
