local Util = require("lazyvim.util")

return {
  {
    "telescope.nvim",
    keys = {
      -- silent alternative for find files that I'm used to
      { "<leader>oo", Util.telescope("files"), desc = "which_key_ignore" },
      -- keymaps for treesitter current functions
      { "<leader>c@", "<cmd>GetCurrentFunctions<cr>", desc = "Find Functions" },
      { "<leader>@", "<cmd>GetCurrentFunctions<cr>", desc = "which_key_ignore" },
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
  },
}
