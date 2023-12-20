local Util = require("lazyvim.util")

return {
  {
    "telescope.nvim",
    keys = {
      -- silent alternative for find files that I'm used to
      { "<leader>oo", Util.telescope("files"), desc = "which_key_ignore" },
      -- keymaps for treesitter current functions
      { "<leader>cF", "<cmd>GetCurrentFunctions<cr>", desc = "Find Functions" },
      { "<leader>@", "<cmd>GetCurrentFunctions<cr>", desc = "which_key_ignore" },
      -- keymap to resume previous telescope search
      { "<leader>fa", Util.telescope("resume"), desc = "Resume Last Search" },
    },
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
      { "eckon/treesitter-current-functions" },
    },
    opts = {
      pickers = {
        lsp_document_symbols = {
          fname_width = 10,
          symbol_width = 78,
          show_line = false,
        },
      },
    },
  },
}
