return {
  "goolord/alpha-nvim",
  dependencies = {
    "kyazdani42/nvim-web-devicons",
  },
  config = function()
      local alpha = require('alpha')
      local startify = require('alpha.themes.startify')
      startify.section.header.val = {
        [[  _____                                    ]],
        [[ |  _  |___ _ _ ___ ___                    ]],
        [[ |     |- _| | |  _| -_|                   ]],
        [[ |__|__|___|___|_| |___|                   ]],
        [[                                           ]],
        [[                                           ]],
        [[     _____                 _               ]],
        [[    |     |___ ___ ___ ___| |_ ___ ___     ]],
        [[    |  |  | . | -_|  _| .'|  _| . |  _|    ]],
        [[    |_____|  _|___|_| |__,|_| |___|_|      ]],
        [[          |_|                              ]],
        [[                                           ]],
        [[                    _____                  ]],
        [[                   |   | |___ _ _ _ _ ___  ]],
        [[                   | | | | -_|_'_| | |_ -| ]],
        [[                   |_|___|___|_,_|___|___| ]],
      }
      alpha.setup(startify.config)
  end
}

