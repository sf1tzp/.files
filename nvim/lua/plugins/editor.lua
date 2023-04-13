local Util = require("lazyvim.util")

return {
  {
    "telescope.nvim",
    keys = {
      { "<leader>oo", Util.telescope("files"), desc = "which_key_ignore" },
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
