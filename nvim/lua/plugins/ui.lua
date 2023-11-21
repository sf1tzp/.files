-- Configuration overrides for the builtin LazyVim `ui` plugins
return {
  {
    "rcarriga/nvim-notify",
    enabled = false,
    keys = {
      { "<leader>un", "<cmd>Telescope notify<cr>", desc = "Show Notification History" },
      {
        "<leader>und",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Delete all Notifications",
      },
      opts = {
        max_width = function()
          return math.floor(vim.o.columns * 0.55)
        end,
      },
    },

    config = function()
      require("telescope").load_extension("notify")
    end,
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    opts = {
      options = {
        separator_style = "padded_slant",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "everforest",
      },
    },
  },
  {
    "SmiteshP/nvim-navic",
    opts = function(_, opts)
      opts.highlight = false
    end,
  },
  {
    "goolord/alpha-nvim",
    keys = {
      { "<leader>ua", "<cmd>Alpha<cr>", desc = "Show Alpha Dashboard" },
    },
    config = function(_, opts)
      local marginTopPercent = 0.1
      local headerPadding = vim.fn.max({ 2, vim.fn.floor(vim.fn.winheight(0) * marginTopPercent) })
      vim.cmd([[highlight AzureBlue guifg=#0080FF gui=nocombine]])
      local heading = [[
 _____
|  _  |___ _ _ ___ ___
|     |- _| | |  _| -_|
|__|__|___|___|_| |___|


    _____                 _
   |     |___ ___ ___ ___| |_ ___ ___
   |  |  | . | -_|  _| .'|  _| . |  _|
   |_____|  _|___|_| |__,|_| |___|_|
         |_|

                   _____
                  |   | |___ _ _ _ _ ___
                  | | | | -_|_'_| | |_ -|
                  |_|___|___|_,_|___|___|
      ]]
      local dashboard = require("alpha.themes.dashboard")
      dashboard.opts = opts
      dashboard.section.header.val = vim.split(heading, "\n")
      dashboard.section.header.opts.hl = "AzureBlue"
      dashboard.config.layout = {
        { type = "padding", val = headerPadding },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        dashboard.section.footer,
      }
      require("alpha").setup(dashboard.config)
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      symbol = "▏",
    },
  },
}
