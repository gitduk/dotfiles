require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- buffer
map("n", "L", ":bn<cr>", { desc = "buffer next" })
map("n", "H", ":bp<cr>", { desc = "buffer previous" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- quick header
vim.keymap.set("n", "<C-k>", function()
  local line = vim.fn.getline "."
  local cs = vim.bo.commentstring or "# %s"
  local comment_sym = vim.trim(cs:match "^(.-)%%s" or "#")

  local pad = " "
  local side = comment_sym:rep(3) -- 三个注释符用于中间行包裹
  local middle_content = side .. pad .. line .. pad .. side

  -- 为了让边框长度与中间行一致，我们使用字符宽度计算而不是注释符重复次数
  local total_width = vim.fn.strdisplaywidth(middle_content)
  local border_unit = comment_sym:sub(1, 1) -- 只用单个字符来画边框（美观）
  local border_line = border_unit:rep(total_width)

  local lnum = vim.fn.line "."
  vim.fn.setline(lnum, border_line)
  vim.fn.append(lnum, middle_content)
  vim.fn.append(lnum + 1, border_line)

  -- 可选：是否调用注释命令
  -- vim.cmd(lnum .. "," .. (lnum + 2) .. "normal gcc")
end, { desc = "Adaptive boxed comment header" })
