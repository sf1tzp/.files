return {
  "sindrets/diffview.nvim",
  lazy = false,
  config = function()
    require("diffview").setup()
  end,
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diff View" },
    { "<leader>gD", "<cmd>DiffviewFileHistory<cr>", desc = "Open Diff View" },
  },
}
