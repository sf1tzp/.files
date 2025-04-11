return function()
  -- Display and UI
  vim.opt.mouse = "a"                -- Enable mouse support
  vim.opt.termguicolors = false      -- Use terminal colors
  vim.opt.number = true              -- Show line numbers
  vim.opt.relativenumber = true      -- Show relative line numbers
  vim.opt.title = true               -- Show Window Title
  vim.opt.cursorline = true          -- Highlight current line
  vim.opt.signcolumn = "yes"         -- Always show the signcolumn
  vim.opt.scrolloff = 8              -- Minimum screen lines above/below cursor
  vim.opt.sidescrolloff = 8          -- Minimum screen columns left/right of cursor
  vim.opt.wrap = false               -- Don't wrap long lines
  vim.opt.showbreak = "↪ "           -- String to show at start of wrapped lines
  vim.opt.list = true                -- Show invisible characters
  vim.opt.listchars = {              -- How to show invisible characters
    tab = "→ ",
    trail = "·",
    extends = "»",
    precedes = "«",
    nbsp = "␣",
  }

  -- Editing and Behavior
  vim.opt.joinspaces = false         -- Don't double-space after joining lines
  vim.opt.virtualedit = "block"      -- Allow cursor placement where there is no character in visual block
  vim.opt.formatoptions:remove({ "c", "r", "o" }) -- Don't auto-comment when pressing enter
  -- vim.opt.clipboard = "unnamedplus"  -- Use system clipboard
  vim.keymap.set('n', "<leader>x", "<cmd>only<cr>", { desc = "Close other splits" })

  -- Autosave when switching files
  vim.opt.autowrite = true
  vim.opt.autowriteall = true
  vim.opt.hidden = true
  vim.opt.switchbuf = "useopen"
  -- Audosave on BufLeave and FocusLost
  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
     callback = function()
       if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
         vim.api.nvim_command("silent update")
       end
     end,
  })

  -- Reopen files at their last position
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local lcount = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= lcount then
        vim.api.nvim_win_set_cursor(0, mark)
      end
    end,
  })

  -- Search
  vim.opt.ignorecase = true          -- Case insensitive searching
  vim.opt.smartcase = true           -- Case-sensitive if uppercase present
  vim.opt.incsearch = true           -- Show search matches while typing
  vim.opt.hlsearch = true            -- Highlight search results

  -- File Handling
  vim.opt.swapfile = false           -- Don't use swapfile
  vim.opt.backup = false             -- Don't keep backup files
  vim.opt.undofile = true            -- Persistent undo history
  vim.opt.undodir = vim.fn.stdpath("data") .. "/undo" -- Undo directory

  -- Default Indentation
  vim.opt.expandtab = true           -- Use spaces instead of tabs
  vim.opt.tabstop = 2                -- Width of tab character
  vim.opt.softtabstop = 2            -- Tab key indentation length
  vim.opt.shiftwidth = 2             -- Width of autoindent
  vim.opt.smartindent = true         -- Insert indents automatically
  vim.opt.autoindent = true          -- Copy indent from current line

  -- Language-specific indentation
  local two_space_indent = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
  end

  local four_space_indent = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end

  local tab_indent = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "javascript", "shell", "typescript", "json", "yaml", "html", "css" },
    callback = two_space_indent,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "go", "gomod", "gosum" },
    callback = tab_indent,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "rust", "java" },
    callback = four_space_indent
  })

  -- Performance
  vim.opt.updatetime = 250           -- Faster update time (CursorHold)
  vim.opt.timeoutlen = 300           -- Time to wait for a mapped sequence
  vim.opt.lazyredraw = true          -- Don't redraw screen during macros
end
