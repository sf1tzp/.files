-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- code rulers
vim.opt.colorcolumn = { "80", "120" }

-- whitespace characters
vim.opt.list = false
vim.g.strip_whitespace_on_save = 1

-- git blame
vim.g.gitblame_enabled = 0 -- don't render by default
vim.g.gitblame_date_format = "%r"
vim.g.gitblame_message_template = "\t\t\t\t\t<author>, <date> <sha> <summary>"

-- templ file association
vim.filetype.add({
  extension = {
    templ = "templ",
  },
})
