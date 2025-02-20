return {
	-- add gruvbox
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			local config = {
				overrides = {
					SignColumn = { bg = "#282828" },
				},
			}
			require("gruvbox").setup(config)
		end,
		init = function()
			-- Load the colorscheme here.
			-- Like many other themes, this one has different styles, and you could load
			-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
			vim.cmd.colorscheme("gruvbox")
		end,
	},
	{
		"NvChad/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
		lazy = true,
	},
	{
		"folke/tokyonight.nvim",
	},
	{
		"catppuccin/nvim",
		lazy = true,
		name = "catppuccin",
	},
	{ "projekt0n/github-nvim-theme" },
	{ "rebelot/kanagawa.nvim" },
	{ "Shatur/neovim-ayu" },
	{ "sainnhe/everforest" },
	{ "loctvl842/monokai-pro.nvim" },
	{ "nyoom-engineering/oxocarbon.nvim" },
	{ "savq/melange-nvim" },
	{ "AlexvZyl/nordic.nvim" },
}
