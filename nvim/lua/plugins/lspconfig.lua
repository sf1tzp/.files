return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      roc_ls = {
        mason = false,
        cmd = { "~/oss/roc/target/release/roc_ls" },
        filetypes = { "roc" },
      },
    },
  },
}
