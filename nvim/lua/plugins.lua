-- Set up Packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- autocommand that reloads neovim and installs/updates/removes plugins
-- when file is saved
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins-setup.lua source <afile> | PackerSync
  augroup end
]])

-- import packer safely
local status, packer = pcall(require, "packer")
if not status then
  return
end
return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Themes
  use 'folke/tokyonight.nvim'
  use 'cocopon/iceberg.vim'
  use 'ellisonleao/gruvbox.nvim'
  use 'rebelot/kanagawa.nvim'
  use 'EdenEast/nightfox.nvim'

  -- Feature Plugins
  use 'nvim-lua/plenary.nvim' -- lua functions (used by other plugins)
  use 'kylechui/nvim-surround' -- quote/unqote motions
  use 'numToStr/Comment.nvim' -- comment motions
  use {                        -- status bar
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
  }
  use 'christoomey/vim-tmux-navigator' -- tmux integration
  use 'inkarkat/vim-ReplaceWithRegister' -- paste over motion
  use 'lukas-reineke/indent-blankline.nvim' -- indent highlighting
  use 'ntpeters/vim-better-whitespace' -- trailing whitespace
  use 'mbbill/undotree' -- better undo history
  use 'tpope/vim-fugitive' -- use git without leaving vim
  use 'gorbit99/codewindow.nvim' -- minimap
  use "windwp/nvim-autopairs" -- add closing brackets and quotes
  use 'dstein64/vim-startuptime' -- measure startup time with :StartupTime

  -- File Navigation
  use 'ThePrimeagen/harpoon' -- mark files and hop between them
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = "make" }
  use { 'nvim-telescope/telescope.nvim', branch = '0.1.x' }

  -- Treesitter (Syntax Tree Highlighting)
  use { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" }
  use 'eckon/treesitter-current-functions' -- jump around between functions

  -- Language Server
  use 'simrat39/rust-tools.nvim' -- configures rust-analyzer lspconfig

  use {
    'VonHeikemen/lsp-zero.nvim',
    requires = {
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
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)

