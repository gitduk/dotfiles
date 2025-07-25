return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { "OXY2DEV/markview.nvim" },
  build = ":TSUpdate",
  lazy = false,
  config = function()
    local configs = require "nvim-treesitter.configs"

    configs.setup {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "elixir",
        "heex",
        "markdown",
        "markdown_inline",
        "html",
        "yaml",
        "typst",
      },
      sync_install = false,
      highlight = {
        enable = true,
        disable = { "just" },
      },
      indent = { enable = true },
    }
  end,
}
