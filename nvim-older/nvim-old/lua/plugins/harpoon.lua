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
    -- Add a section to which-key for harpoon
    local wk = require("which-key")
    wk.register({
      ["<leader>h"] = { name = "+harpoon" },
    })
  end,

  keys = function()
    local harpoon = require("harpoon")

    return {
      {
        "<leader>ha",
        function()
          harpoon:list():append()
        end,
        desc = "Harpoon: Mark File",
      },
      {
        "<leader>hh",
        function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: Show Files",
      },

      -- Keybindings to jump between files 1-9
      {
        "<leader>h1",
        function()
          harpoon:list():select(1)
        end,
        desc = "Open File 1",
      },
      {
        "<leader>h2",
        function()
          harpoon:list():select(2)
        end,
        desc = "Open File 2",
      },
      {
        "<leader>h3",
        function()
          harpoon:list():select(3)
        end,
        desc = "Open File 3",
      },
      {
        "<leader>h4",
        function()
          harpoon:list():select(4)
        end,
        desc = "Open File 4",
      },
      {
        "<leader>h5",
        function()
          harpoon:list():select(5)
        end,
        desc = "Open File 5",
      },
      {
        "<leader>h6",
        function()
          harpoon:list():select(6)
        end,
        desc = "Open File 6",
      },
      {
        "<leader>h7",
        function()
          harpoon:list():select(7)
        end,
        desc = "Open File 7",
      },
      {
        "<leader>h8",
        function()
          harpoon:list():select(8)
        end,
        desc = "Open File 8",
      },
      {
        "<leader>h9",
        function()
          harpoon:list():select(9)
        end,
        desc = "Open File 9",
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
