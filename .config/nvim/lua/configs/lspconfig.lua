-- read :h vim.lsp.config for changing options of lsp servers
require("nvchad.configs.lspconfig").defaults()

local servers = {
  html = {},
  cssls = {},
  bashls = {
    filetypes = { "sh", "zsh" },
  },
  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          typeCheckingMode = "basic",
        },
      },
    },
  },
  rust_analyzer = {},
  jsonls = {},
  taplo = {},
  yamlls = {},
  lua_ls = {},
}

for name, opts in pairs(servers) do
  vim.lsp.enable(name)
  vim.lsp.config(name, opts)
end
