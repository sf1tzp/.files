return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Oil"},
    opts = {
      -- Oil will take over directory buffers (e.g. `vim .` or `:e directory`)
      default_file_explorer = true,
      -- Id is automatically added at the beginning, and name at the end
      -- See :help oil-columns
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },
      -- Buffer-local options to use for oil buffers
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },
      -- Window-local options to use for oil buffers
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      -- Send deleted files to trash instead of permanently deleting them
      delete_to_trash = false,
      -- Skip the confirmation popup for simple operations
      skip_confirm_for_simple_edits = false,
      -- Change oil's directory for each tab
      use_default_keymaps = false,
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<ESC>"] = "actions.close",
        ["q"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["H"] = "actions.toggle_hidden",
      },

      view_options = {
        sort = {
          -- Sort order can be "asc" or "desc"
          -- See :help oil-columns to see which columns are sortable
          { "type", "desc" },
          { "name", "asc" },
        },
      },
      -- Configuration for the floating window in oil.open_float
      float = {
        padding = 2,
        max_width = 0.85,
        max_height = 0.80,
        border = "single",
        win_options = {
          winblend = 0,
        },
        preview_split = "right",
        -- This is the config that will be passed to nvim_open_win.
        -- Override any of the above by adding an override to this table
        override = function(conf)
          return conf
        end,
      },
      -- Configuration for the actions floating preview window
      preview_win = {
        update_on_cursor_moved = true,
        disable_preview = function(filename)
          print(filename)
          if string.find(filename, "%.env") then return true end
          if string.find(filename, "%.tokens") then return true end
          return false
        end,
      },
    },

    keys = {
      { "<leader>fo", "<CMD>Oil --float --preview<CR>", desc = "Open file explorer in float (Oil)" },
    },
  },
}
