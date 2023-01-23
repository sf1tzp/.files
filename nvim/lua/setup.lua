-- color scheme
require("gruvbox").setup()

-- status bar
require('lualine').setup({
  options = { theme = 'everforest' }
})

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

-- code coverage
require("coverage").setup({
  lang = {
    go = {
      coverage_file = "./out/tests/unit/full_coverage.out"
    }
  }
})

-- git blame
vim.g.gitblame_enabled = 0 -- don't render by default
vim.g.gitblame_date_format = '%r'
vim.g.gitblame_message_template = '\t\t\t\t\t<author>, <date> <sha> <summary>'

-- git diffview
require("diffview").setup()

-- obsidian
require("obsidian").setup({
  dir = "~/mine/notes",
  completion = {
    nvim_cmp = true, -- if using nvim-cmp, otherwise set to false
  }
})

