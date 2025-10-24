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
        enable = true,
        headings = presets.headings.glow,
        horizontal_rules = presets.horizontal_rules.dashed,
        tables = presets.tables.none,
        list_items = {
          enable = true,
          wrap = true,
          indent_size = function (buffer)
              if type(buffer) ~= "number" then
                  return vim.bo.shiftwidth or 4;
              end
              return vim.bo[buffer].shiftwidth or 4;
          end,
          shift_width = 2,
        },
      },
    }
  end,

  -- keys
  keys = {
    { "<leader>mm", "<cmd>Markview<cr>", desc = "Toggle Markview" },
  },
}
