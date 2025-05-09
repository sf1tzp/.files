return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑ               CÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      dÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆ#                                                                  /ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆ      ÆÆÆÆÆÆÆÆÆÆÆÆ´      ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆ      ÆÆÆÆÆÆÆÆÆÆ       ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆ      ÆÆÆÆÆÆÆÆ       ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆ      ÆÆÆÆÆÆ       ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆ      `ÆÆË      .ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ      ÆÆÆÆÆ      CÆÆÆÆ\                                             ÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
                    -- [[   ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ   ]],
        [[                                                                                                                                       ]],
        [[                                                                                                                                       ]],
        [[                                         +++++++++++++++++++                                                                           ]],
        [[                                     +++++++++++++++++++++++    +++++++++                                                              ]],
        [[                                    +++++++++π                  +++++++++                                                              ]],
        [[                                    +++++++++                   +++++++++                                                              ]],
        [[         +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                   ]],
        [[          ÷++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                  ]],
        [[                                    +++++++++      +++++++++    +++++++++                +++++++++-                                    ]],
        [[                                    +++++++++      +++++++++    +++++++++              +++++++++=                                      ]],
        [[                                    +++++++++      +++++++++    +++++++++           ≈++++++++-                                         ]],
        [[                                    +++++++++      +++++++++    +++++++++         ≠++++++++-                                           ]],
        [[                                    +++++++++      +++++++++    +++++++++       =++++++++-                                             ]],
        [[                                    +++++++++      +++++++++    ×+++++++++    +++++++++                                                ]],
        [[                                    +++++++++      +++++++++     π+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++=       ]],
        [[                                    ×××××××××      ×××××××××       π≠≠≠≠≠÷×××××××××××××××××××××××××××××××××××××××××××××××××××××××      ]],
        [[                                                                                                                                       ]],
        [[                                                                                                                                       ]],

      }
      -- Configure button styling
      dashboard.section.buttons.val = {
        -- dashboard.button("o", "  [ ] Open Oil", "<CMD>Oil --float --preview<CR>"),
        dashboard.button("f", "  [ ] Find file", ":Telescope find_files <CR>"),
        dashboard.button("r", "  [ ] Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", "  [ ] Find text", ":Telescope live_grep <CR>"),
        dashboard.button("h", "  [ ] Harpoon List", ":lua require('harpoon.ui'):toggle_quick_menu(require('harpoon'):list()) <CR>"),
        dashboard.button("c", "  [ ] Edit init.lua", ":e $MYVIMRC <CR>"),
        dashboard.button("l", "  [ ] Lazy Plugin Manager", ":Lazy<CR>"),
        dashboard.button("q", "  [ ] Quit", ":qa<CR>"),
      }
      -- Footer
      local function footer()
        local version = vim.version()
        local nvim_version_info = "v" .. version.major .. "." .. version.minor .. "." .. version.patch
        local cwd = vim.fn.getcwd()
        return string.format("Neovim %s | %s", nvim_version_info, cwd)
      end
      dashboard.section.footer.val = footer()
      -- Layout options
      dashboard.opts.layout = {
        { type = "padding", val = 2 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 2 },
        dashboard.section.footer,
      }
      return dashboard
    end,
    config = function(_, dashboard)
      -- Close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end
      require("alpha").setup(dashboard.opts)
      -- Hide tabline and statusline on dashboard
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        desc = "Hide status, tab, and indent lines when in Alpha",
        callback = function()
          vim.b.miniindentscope_disable = true
          vim.opt.laststatus = 0
          vim.api.nvim_create_autocmd("BufUnload", {
            buffer = 0,
            desc = "Restore status, tab, and indent lines when leaving Alpha",
            callback = function()
              vim.b.miniindentscope_disable = false
              vim.opt.laststatus = 3
            end,
          })
        end,
      })
    end,
  },
}
