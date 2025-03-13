return {
    { 'echasnovski/mini.basics' },
    {
        'echasnovski/mini.ai',
        -- use mini.ai to expand selections, eg to around / inside:
        -- `va""` expands visual selection to include the surrounding ""s
        -- `vi""` expands visual selection to just inside the surrounding ""s
        opts = {
            mappings = {
                -- Main textobject prefixes
                around = 'a',
                inside = 'i',
            }
        }
    },
    {
        'echasnovski/mini.comment',
        opts = {
            mappings = {
                -- Toggle comment (like `gcip` - comment inner paragraph) for both
                -- Normal and Visual modes
                comment = 'gc',

                -- Toggle comment on current line
                comment_line = 'gc',

                -- Toggle comment on visual selection
                comment_visual = 'gc',

                -- Define 'comment' textobject (like `dgc` - delete whole comment block)
                -- Works also in Visual mode if mapping differs from `comment_visual`
                textobject = 'gc',
            }
        }
    },
    {
        'echasnovski/mini.jump',
        -- use mini.jump to extend the range of f/t/F/T seach commands
        opts = {
            mappings = {
                forward = 'f',
                backward = 'F',
                forward_till = 't',
                backward_till = 'T',
                repeat_jump = ';',
            },
        }
    },
    {
        'echasnovski/mini.jump2d',
        -- use mini.jump2d to jump to any word start '<leader>j'
        -- Word starts will be highlighted with a sequence of characters to type
        opts = {
            allowed_windows = { not_current = false }, -- only allow on the active window
            labels = "wersdfxcvuiojklmRFVUIOJKLM",     -- keys that will appear in the target sequence
            allowed_lines = {
                blank = false,                         -- Blank line (not sent to spotter even if `true`)
                fold = false,                          -- Start of fold (not sent to spotter even if `true`)
            },
            view = {
                dim = true,        -- dim the surrounding character
                n_steps_ahead = 3, -- show up to three target sqeuence at once
            },
            mappings = {
                start_jumping = '', -- unbind default, map 'word_start' search just below:
            },
        },
        keys = {
            { "<leader>j", ":lua MiniJump2d.start(MiniJump2d.builtin_opts.word_start)<cr>" },
        },
        config = function(_, opts)
            -- use a configure function to set highlight colors
            require('mini.jump2d').setup(opts)
            vim.api.nvim_set_hl(0, 'MiniJump2dSpot', { fg = '#ff9e64', bg = '#292e42', italic = false })
            vim.api.nvim_set_hl(0, 'MiniJump2dSpotUnique', { fg = '#1abc9c', bg = '#292e42', italic = false })
            vim.api.nvim_set_hl(0, 'MiniJump2dSpotAhead', { fg = '#1abc9c', bg = '#292e42', italic = false })
            vim.api.nvim_set_hl(0, 'MiniJump2dDim', { fg = '#565f89', italic = false })
        end,
    },
    {
        'echasnovski/mini.move',
        opts = {
            mappings = {
                -- Move visual selection in Visual mode.
                left = '<S-h>',
                right = '<S-l>',
                down = '<S-j>',
                up = '<S-k>',

                -- -- Move current line in Normal mode (unbound)
                line_left = '',
                line_right = '',
                line_down = '',
                line_up = '',
            },
        }
    },
    {
        'echasnovski/mini.pairs',
        opts = {
            mappings = {
                -- -- Slight change to the default config:
                -- -- Don't insert pairs of quotes when directly next to a word (or after a '\')
                ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\][^%w]", register = { cr = false } },
                ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^\\][^%w]", register = { cr = false } },
                ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\][^%w]", register = { cr = false } },
            }
        }
    },
    {
        'echasnovski/mini.surround',
        -- use mini.surround to add or remove surrounding character, eq
        -- `vWsa"` selects a Word and puts "" around it
        -- `sr"'` replaces the surrounding "" with ''
        opts = {
            mappings = {
                add = 'sa',       -- Add surrounding in Normal and Visual modes
                delete = 'sd',    -- Delete surrounding
                find = 'sf',      -- Find surrounding (to the right)
                find_left = 'sF', -- Find surrounding (to the left)
                highlight = 'sh', -- Highlight surrounding
                replace = 'sr',   -- Replace surrounding
            },
        }
    },
}
