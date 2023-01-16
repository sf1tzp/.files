-- color scheme
require("gruvbox").setup()

-- nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require('nvim-tree').setup()

-- lsp-zero
require("lsp")

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
  ensure_installed = { "lua", "rust", "toml" },
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

