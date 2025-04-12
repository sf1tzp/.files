return {
  "ThePrimeagen/harpoon",
  enabled = true,
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/which-key.nvim",
  },

  config = function()
    require("harpoon").setup({
      menu = {
        width = 100,
      },
      settings = {
        save_on_toggle = true,
      },
    })
  end,

  keys = function()
    local harpoon = require("harpoon")

    return {
      {
        "<leader>ha",
        function()
          harpoon:list():add()
        end,
        desc = "Harpoon: Mark File",
      },
      {
        "<leader>hp",
        function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: Show Files",
      },

      -- Silent Keybindings of the same
      {
        "<leader>1",
        function()
          harpoon:list():select(1)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>2",
        function()
          harpoon:list():select(2)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>3",
        function()
          harpoon:list():select(3)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>4",
        function()
          harpoon:list():select(4)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>5",
        function()
          harpoon:list():select(5)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>6",
        function()
          harpoon:list():select(6)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>7",
        function()
          harpoon:list():select(7)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>8",
        function()
          harpoon:list():select(8)
        end,
        desc = "which_key_ignore",
      },
      {
        "<leader>9",
        function()
          harpoon:list():select(9)
        end,
        desc = "which_key_ignore",
      },
    }
  end,
}
