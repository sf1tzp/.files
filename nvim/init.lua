if vim.g.vscode then
  print("Using empty init.lua for VS Code Extension")
else
  require("options")
  require("plugins")
  require("lsp")
  require("setup")

  -- define keymaps after plugin setup
  require("keymap")
end

