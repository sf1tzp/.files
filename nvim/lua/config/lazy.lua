-- Bootstrap lazy.nvim
-- Modified from https://lazy.folke.io/installation
--
-- This module allows configuring the lazy "spec" (list of plugins to install)
-- require("config.lazy").setup({ spec = {
-- 	{ import = "..." },
-- 	{ import = "..." },
-- }})
--
-- If no spec is provided, everything in the plugins directory will be loaded
--
local M = {}

local default_plugins = {
	{ import = "plugins" }, -- everything in the "plugins" directory
}

function M.setup(opts)
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		local lazyrepo = "https://github.com/folke/lazy.nvim.git"
		local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
		if vim.v.shell_error ~= 0 then
			vim.api.nvim_echo({
				{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
				{ out, "WarningMsg" },
				{ "\nPress any key to exit..." },
			}, true, {})
			vim.fn.getchar()
			os.exit(1)
		end
	end
	vim.opt.rtp:prepend(lazypath)

	local spec = opts and opts.spec or default_plugins

	-- Setup lazy.nvim
	require("lazy").setup({
		spec = spec,
		-- automatically check for plugin updates
		checker = { enabled = false },
	})
end

return M
