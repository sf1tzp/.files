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
  use 'tpope/vim-surround' -- quote/unqote motions
  use 'numToStr/Comment.nvim' -- comment motions
  use 'nvim-lualine/lualine.nvim' -- status bar
  use 'christoomey/vim-tmux-navigator' -- tmux integration
  use 'inkarkat/vim-ReplaceWithRegister' -- paste over motion

  -- File Tree and Fuzzy Finder
  use 'nvim-tree/nvim-tree'
  use 'nvim-tree/nvim-web-devicons'
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = "make" }
  use { 'nvim-telescope/telescope.nvim', branch = '0.1.x' }

  -- Language Server
  use("williamboman/mason.nvim") -- in charge of managing lsp servers
  use("williamboman/mason-lspconfig.nvim") -- integrates mason & lspconfig
  use("neovim/nvim-lspconfig") -- configure language servers

  if packer_bootstrap then
    require('packer').sync()
  end
end)

