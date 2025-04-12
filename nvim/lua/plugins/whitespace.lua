return {
  {
    "ntpeters/vim-better-whitespace",
    config = function()
      vim.cmd([[highlight ExtraWhitespace guibg=#bc362a gui=nocombine]])
    end,
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      draw = {
        -- Delay (in ms) between event and start of drawing scope indicator
        delay = 0,
      },
      symbol = "▏",
    },
    config = function(_, opts)
      local indentscope = require('mini.indentscope')
      opts["draw"]["animation"] = indentscope.gen_animation.none()
      require('mini.indentscope').setup(opts)
    end
  },
}
