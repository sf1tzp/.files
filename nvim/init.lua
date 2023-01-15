if vim.g.vscode then
  print("Hello")
    -- VSCode extension
else
    -- ordinary Neovim
    require("keymap")
    require("plugins")
    require("remap")
    require("settings")
    require("startup")
end

