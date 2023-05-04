if vim.g.vscode then
  print("Using empty init.lua for VS Code Extension")
else
  -- bootstrap lazy.nvim, LazyVim and your plugins
  require("config.lazy")
end
