return {
  "rcarriga/nvim-notify",
  enabled = false,
  keys = {
    { "<leader>un", "<cmd>Telescope notify<cr>", desc = "Show Notification History" },
    {
      "<leader>und",
      function()
        require("notify").dismiss({ silent = true, pending = true })
      end,
      desc = "Delete all Notifications",
    },
    opts = {
      max_width = function()
        return math.floor(vim.o.columns * 0.55)
      end,
    },
  },

  config = function()
    require("telescope").load_extension("notify")
  end,
}
