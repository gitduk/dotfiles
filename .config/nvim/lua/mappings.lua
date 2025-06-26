require "nvchad.mappings"

-- add yours here
local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- buffer
map("n", "L", ":bn<cr>", { desc = "Next buffer" })
map("n", "H", ":bp<cr>", { desc = "Prev buffer" })

-- move lines
map("n", "<S-j>", "<cmd>m .1<cr>==", { desc = "Move down" })
map("n", "<S-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("v", "<S-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<S-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })
-- map("i", "<S-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- map("i", "<S-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })

-- move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- quick delete
map("i", "<C-h>", "<BS>", { desc = "Backspace" })
map("i", "<C-l>", "<DEL>", { desc = "Delete" })

-- redo
map("n", "U", ":redo<cr>", { desc = "Redo" })

-- clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- copy
map("v", "Y", '"+yy', { desc = "Copy to system clipboard" })

-- quick header
vim.keymap.set("n", "<leader>k", function()
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
end, { desc = "boxed comment header" })

-- Disable mappings
-- local nomap = vim.keymap.del
-- nomap("i", "<C-k>")
