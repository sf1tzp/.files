-- Configuration overrides for the builtin LazyVim `ui` plugins
return {
  {
    "akinsho/bufferline.nvim",
    enabled = true,
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
    opts = function(_, opts)
      vim.opt.termguicolors = true
      vim.cmd([[highlight IndentBlanklineIndent1 guibg=#323232 gui=nocombine]])
      vim.cmd([[highlight IndentBlanklineIndent2 guibg=#413d3b gui=nocombine]])

      opts.char = ""
      opts.char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
      }
      opts.space_char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
      }
      opts.show_trailing_blankline_indent = false
      return opts
    end,
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      symbol = "▏",
    },
  },
}
