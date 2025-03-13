if vim.g.vscode then
  require("config.keymaps")
  print("Using empty init.lua for VS Code Extension")
  require("config.keymaps")
else
  -- bootstrap lazy.nvim, LazyVim and your plugins
  require("config.lazy")
end
