local Util = require("lazyvim.util")

return {
  {
    "telescope.nvim",
    keys = {
      { "<leader>oo", Util.telescope("files"), desc = "Find Files (root dir)" },
    },
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },
}
