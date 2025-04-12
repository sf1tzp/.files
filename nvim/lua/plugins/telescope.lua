return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Telescope",
    keys = {
      -- Find files
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },

      -- Find text
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Find Text" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Find Word Under Cursor" },

      -- Workspace symbols
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace Symbols" },

      -- Additional helpful searches
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find Buffers" },
      { "<leader>H", "<cmd>Telescope help_tags<CR>", desc = "Neovim Help" },
    },
    opts = {
      defaults = {
        file_ignore_pattersn = { "%.env", "%.tokens" },
        prompt_prefix = "❯ ",
        selection_caret = "❯ ",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
            preview_width = 0.55,
            results_width = 0.8,
          },
          width = 0.85,
          height = 0.80,
          preview_cutoff = 120,
        },
        path_display = { "truncate" },
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        color_devicons = true,
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      -- Load the FZF extension
      require("telescope").load_extension("fzf")
    end,
  },
}
