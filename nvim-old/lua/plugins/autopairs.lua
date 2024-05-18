return {
  "echasnovski/mini.pairs",
  config = function()
    require("mini.pairs").setup({
      mappings = {
        -- Slight change to the default config:
        -- Don't insert pairs of quotes when directly next to a word (or after a '\')
        ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
        ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
        ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
      },
    })
  end,
}
