if vim.g.vscode then
  print("Using empty init.lua for VS Code Extension")
else
  require("plugins")
  require("lsp")
  require("setup")

  -- customize after plugin setup
  require("options")
  require("keymap")
end

