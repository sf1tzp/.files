return {
    {
"RRethy/base16-nvim"
  },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", "RRethy/base16-nvim" },
        event = "VeryLazy",
        opts = {
            options = {
                icons_enabled = true,
                theme = "everforest",
                -- component_separators = { left = ">", right = "<" },
                -- sectio_separators = { left = ">>", right = ">>" },
                disabled_filetypes = {
                    statusline = { "dashboard", "alpha", "oil", "TelescopePrompt" },
                    winbar = { "dashboard", "alpha", "oil", "TelescopePrompt" },
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = true,
                refresh = {
                    statusline = 100,
                    tabline = 100,
                    winbar = 100,
                }
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    "branch",
                    { "diff", symbols = { added = " ", modified = " ", removed = " " } },
                },
                lualine_c = {
                    { "filename", path = 1 }, -- 0 = just filename, 1 = relative path, 2 = absolute path
                    {
                        "diagnostics",
                        sources = { "nvim_lsp" },
                        symbols = { error = " ", warn = " ", info = " ", hint = " " },
                    },
                },
                lualine_x = { "filetype" }, -- "encoding", "fileformat"
                lualine_y = { "progress" },
                lualine_z = { "location" }
            },
            -- inactive_sections = {
            --     lualine_a = {},
            --     lualine_b = {},
            --     lualine_c = { "filename" },
            --     lualine_x = { "location" },
            --     lualine_y = {},
            --     lualine_z = {}
            -- },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = { "oil", "lazy", "mason", "trouble" }
        },
    },
}

-- return {
--   {
--     "akinsho/bufferline.nvim",
--     enabled = false,
--     opts = {
--       options = {
--         separator_style = "padded_slant",
--       },
--     },
--   },
--   {
--     "nvim-lualine/lualine.nvim",
--     opts = {
--       options = {
--         theme = "everforest",
--       },
--     },
--   },
--   {
--     "SmiteshP/nvim-navic",
--     opts = function(_, opts)
--       opts.highlight = false
--     end,
--   },
-- }
