return {
  -- Themes
  'folke/tokyonight.nvim',
  'cocopon/iceberg.vim',
  'ellisonleao/gruvbox.nvim',
  'rebelot/kanagawa.nvim',
  'EdenEast/nightfox.nvim',

  -- Status Bar
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons', opt = true },
  },

  -- Feature Plugins
  'nvim-lua/plenary.nvim', -- lua functions (used by other plugins)
  'kylechui/nvim-surround', -- quote/unqote motions
  'numToStr/Comment.nvim', -- comment motions
  'christoomey/vim-tmux-navigator', -- tmux integration
  'inkarkat/vim-ReplaceWithRegister', -- paste over motion
  'lukas-reineke/indent-blankline.nvim', -- indent highlighting
  'ntpeters/vim-better-whitespace', -- trailing whitespace
  'mbbill/undotree', -- better undo history
  'tpope/vim-fugitive', -- use git without leaving vim
  'windwp/nvim-autopairs', -- add closing brackets and quotes
  'dstein64/vim-startuptime', -- measure startup time with :StartupTime
  'christianrondeau/vim-base64', -- base 64 extension
  'andythigpen/nvim-coverage', -- coverage report visualiztion
  'f-person/git-blame.nvim', -- git blame inline
  'sindrets/diffview.nvim', -- git diff viewer
  'epwalsh/obsidian.nvim', -- obsidian integration

  -- File Navigation
  'ThePrimeagen/harpoon', -- mark files and hop between them
  { 'nvim-telescope/telescope-fzf-native.nvim', build = "make" },
  { 'nvim-telescope/telescope.nvim', branch = '0.1.x' },

  -- Treesitter (Syntax Tree Highlighting)
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate"
  },
  { 'nvim-treesitter/playground'},
  'eckon/treesitter-current-functions', -- jump around between functions

  -- Language Server
  'simrat39/rust-tools.nvim', -- configures rust-analyzer lspconfig

  {
    'VonHeikemen/lsp-zero.nvim',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      -- Snippet Collection (Optional)
      {'rafamadriz/friendly-snippets'},
    }
  },

}

