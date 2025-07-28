return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  -- For `nvim-treesitter` users.
  priority = 49,

  -- For blink.cmp's completion
  -- source
  -- dependencies = {
  --     "saghen/blink.cmp"
  -- },

  config = function()
    local presets = require "markview.presets"
    require("markview").setup {
      markdown = {
        headings = presets.headings.glow,
        horizontal_rules = presets.horizontal_rules.dashed,
        tables = presets.tables.none,
      },
    }
  end,

  -- keys
  keys = {
    { "<leader>mm", "<cmd>Markview<cr>", desc = "Toggle Markview" },
  },
}
