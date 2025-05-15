return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    labels = "asdfghjklqwertyuiopzxcvbnm",
    modes = {
      char = {
        jump_labels = true,
        jump = {
          autojump = true,
        },
      },
    },
  },
  keys = {
    -- disable whe default flash keymap
    { "s", mode = { "n", "x", "o" }, false },
    {
      "w",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
  },
}
