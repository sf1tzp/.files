return {
  "ThePrimeagen/harpoon",
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/which-key.nvim",
  },

  keys = function()
    local ui = require("harpoon.ui")
    local mark = require("harpoon.mark")

    local wk = require("which-key")
    wk.register({
      ["<leader>h"] = { name = "+harpoon" },
    })

    return {
      { "<leader>ha", mark.add_file, desc = "Harpoon: Mark File" },
      { "<leader>hr", mark.rm_file, desc = "Harpoon: Remove File" },
      { "<leader>hs", ui.toggle_quick_menu, desc = "Harpoon: Show Files" },
      { "<leader>hh", ui.toggle_quick_menu, desc = "Harpoon: Show Files" },

      -- Keybindings to jump between files 1-9
      {
        "<leader>h1",
        function()
          require("harpoon.ui").nav_file(1)
        end,
        desc = "Open File 1",
      },
      {
        "<leader>h2",
        function()
          require("harpoon.ui").nav_file(2)
        end,
        desc = "Open File 2",
      },
      {
        "<leader>h3",
        function()
          require("harpoon.ui").nav_file(3)
        end,
        desc = "Open File 3",
      },
      {
        "<leader>h4",
        function()
          require("harpoon.ui").nav_file(4)
        end,
        desc = "Open File 4",
      },
      {
        "<leader>h5",
        function()
          require("harpoon.ui").nav_file(5)
        end,
        desc = "Open File 5",
      },
      {
        "<leader>h6",
        function()
          require("harpoon.ui").nav_file(6)
        end,
        desc = "Open File 6",
      },
      {
        "<leader>h7",
        function()
          require("harpoon.ui").nav_file(7)
        end,
        desc = "Open File 7",
      },
      {
        "<leader>h8",
        function()
          require("harpoon.ui").nav_file(8)
        end,
        desc = "Open File 8",
      },
      {
        "<leader>h9",
        function()
          require("harpoon.ui").nav_file(9)
        end,
        desc = "Open File 9",
      },
      -- Silent Keybindings of the same
      {
        "<leader>1",
        function()
          require("harpoon.ui").nav_file(1)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>2",
        function()
          require("harpoon.ui").nav_file(2)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>3",
        function()
          require("harpoon.ui").nav_file(3)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>4",
        function()
          require("harpoon.ui").nav_file(4)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>5",
        function()
          require("harpoon.ui").nav_file(5)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>6",
        function()
          require("harpoon.ui").nav_file(6)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>7",
        function()
          require("harpoon.ui").nav_file(7)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>8",
        function()
          require("harpoon.ui").nav_file(8)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>9",
        function()
          require("harpoon.ui").nav_file(9)
        end,
        desc = "which_key_ignore",
      },
    }
  end,
}
