-- color scheme
require("gruvbox").setup()

-- status bar
require('lualine').setup({
  options = { theme = 'everforest' }
})

-- nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require('nvim-tree').setup {
  disable_netrw = true,
  -- see :help nvim-tree-setup
  view = {
    -- use float for quit_on_focus_loss
    -- Otherwise, nvim-tree will get in the way when quitting vim when docked
    -- see : https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close
    float = {
      enable = true,
      quit_on_focus_loss = true,
      open_win_config = {
        border = "single",
        height = 100,
      }
    }
  }
}

-- harpoon
require('harpoon').setup()

-- Telescope
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}
require('telescope').load_extension("fzf")

-- Treesitter Plugin Setup
require('nvim-treesitter.configs').setup {
  ensure_installed = { "lua", "vim", "help", "markdown", "go",  "rust", "json", "yaml", "toml" },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting=false,
  },
  ident = { enable = true },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = nil,
  }
}

-- nvim comment and surround
require("nvim-surround").setup()
require("Comment").setup()

-- nvim auto pair w/ treesitter
local npairs = require("nvim-autopairs")
local Rule = require('nvim-autopairs.rule')
npairs.setup({
    check_ts = true,
    ts_config = {
        lua = {'string'},-- it will not add a pair on that treesitter node
    }
})
local ts_conds = require('nvim-autopairs.ts-conds')

-- press % => %% only while inside a comment or string
npairs.add_rules({
  Rule("%", "%", "lua")
    :with_pair(ts_conds.is_ts_node({'string','comment'})),
  Rule("$", "$", "lua")
    :with_pair(ts_conds.is_not_ts_node({'function'}))
})

-- Indent Highlighting
vim.opt.termguicolors = true
vim.cmd [[highlight IndentBlanklineIndent1 guibg=#303030 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guibg=#3a3a3a gui=nocombine]]

require("indent_blankline").setup {
  char = "",
  char_highlight_list = {
    "IndentBlanklineIndent1",
    "IndentBlanklineIndent2",
  },
  space_char_highlight_list = {
    "IndentBlanklineIndent1",
    "IndentBlanklineIndent2",
  },
  show_trailing_blankline_indent = false,
}

-- minimap
local codewindow = require('codewindow')
codewindow.setup({
  minimap_width = 5,
  width_multuplier = 12,
})
codewindow.apply_default_keybinds()

