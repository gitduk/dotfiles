-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local autocmd = vim.api.nvim_create_autocmd

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

autocmd('VimEnter', {
  command = ':silent !alacritty @ set-spacing padding=0 margin=0',
})

autocmd('VimLeavePre', {
  command = ':silent !alacritty @ set-spacing padding=20 margin=10',
})

-- This autocmd will restore cursor position on file open
autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    local line = vim.fn.line '\'"'
    if line > 1 and line <= vim.fn.line '$' and vim.bo.filetype ~= 'commit' and vim.fn.index({ 'xxd', 'gitrebase' }, vim.bo.filetype) == -1 then
      vim.cmd 'normal! g`"'
    end
  end,
})
