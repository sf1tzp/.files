return {
  "ThePrimeagen/harpoon",
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/which-key.nvim",
  },

  config = function()
    require("harpoon").setup()
    -- Add a section to which-key for harpoon
    local wk = require("which-key")
    wk.register({
      ["<leader>h"] = { name = "+harpoon" },
    })
  end,

  keys = {
    { "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "Harpoon: Mark File" },
    { "<leader>hr", "<cmd>lua require('harpoon.mark').rm_file()<cr>", desc = "Harpoon: Remove File" },
    { "<leader>hs", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "Harpoon: Show Files" },
    { "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "Harpoon: Show Files" },

    -- Keybindings to jump between files 1-9
    { "<leader>h1", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", desc = "Open File 1" },
    { "<leader>h2", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", desc = "Open File 2" },
    { "<leader>h3", "<cmd>lua require('harpoon.ui;).nav_file(3)<cr>", desc = "Open File 3" },
    { "<leader>h4", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", desc = "Open File 4" },
    { "<leader>h5", "<cmd>lua require('harpoon.ui').nav_file(5)<cr>", desc = "Open File 5" },
    { "<leader>h6", "<cmd>lua require('harpoon.ui').nav_file(6)<cr>", desc = "Open File 6" },
    { "<leader>h7", "<cmd>lua require('harpoon.ui').nav_file(7)<cr>", desc = "Open File 7" },
    { "<leader>h8", "<cmd>lua require('harpoon.ui').nav_file(8)<cr>", desc = "Open File 8" },
    { "<leader>h9", "<cmd>lua require('harpoon.ui').nav_file(9)<cr>", desc = "Open File 9" },
    -- Silent Keybindings of the same
    { "<leader>1", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", desc = "which_key_ignore" },
    { "<leader>2", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", desc = "which_key_ignore" },
    { "<leader>3", "<cmd>lua require('harpoon.ui;).nav_file(3)<cr>", desc = "which_key_ignore" },
    { "<leader>4", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", desc = "which_key_ignore" },
    { "<leader>5", "<cmd>lua require('harpoon.ui').nav_file(5)<cr>", desc = "which_key_ignore" },
    { "<leader>6", "<cmd>lua require('harpoon.ui').nav_file(6)<cr>", desc = "which_key_ignore" },
    { "<leader>7", "<cmd>lua require('harpoon.ui').nav_file(7)<cr>", desc = "which_key_ignore" },
    { "<leader>8", "<cmd>lua require('harpoon.ui').nav_file(8)<cr>", desc = "which_key_ignore" },
    { "<leader>9", "<cmd>lua require('harpoon.ui').nav_file(9)<cr>", desc = "which_key_ignore" },
  },
}
