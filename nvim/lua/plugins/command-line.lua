return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline_popup", -- use cmdline_popup view
        opts = {
          position = {
            row = "50%",
            col = "50%",
          },
          size = {
            width = "40%",
            height = "auto",
          },
        },
      },
      messages = {
        enabled = true,
        view = "notify",       -- use the notify view for messages
        view_error = "notify", -- display errors in notify view
        view_warn = "notify",  -- display warnings in notify view
      },
      popupmenu = {
        enabled = true,
        backend = "nui", -- use nui for the popupmenu
      },
      lsp = {
        -- Disable LSP progress messages to avoid clutter
        progress = {
          enabled = false,
        },
        override = {
          -- Only show message signatures in a floating window
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = false,        -- classic bottom search
        command_palette = true,       -- command palette similar to VSCode
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false,           -- enables an input dialog for inc-rename.nvim
      },
    },
  }
}
