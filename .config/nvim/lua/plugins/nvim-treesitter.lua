return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,

  opts = {
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
}
