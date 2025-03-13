return {
  "andythigpen/nvim-coverage",
  keys = {
    { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Toggle Code Coverage" },
  },
  config = {
    commands = true, -- create commands
    highlights = {
      -- customize highlight groups created by the plugin
      covered = { fg = "#C3E88D" }, -- supports style, fg, bg, sp (see :h highlight-gui)
      uncovered = { fg = "#F07178" },
    },
    signs = {
      -- use your own highlight groups or text markers
      covered = { hl = "CoverageCovered", text = "▎" },
      uncovered = { hl = "CoverageUncovered", text = "▎" },
    },
    summary = {
      -- customize the summary pop-up
      min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
    },
    lang = {
      -- customize language specific settings
      go = {
        coverage_file = "./out/tests/unit/full_coverage.out",
      },
    },
  },
}
