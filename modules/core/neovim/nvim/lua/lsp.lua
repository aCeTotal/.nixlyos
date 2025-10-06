-- Mason + LSP setup without requiring lspconfig (avoids deprecation warnings)
local mason = require("mason")
local mason_lsp = require("mason-lspconfig")
local lsp_format = require("lsp-format")

mason.setup({})
lsp_format.setup({ eslint = { sync = true } })

-- Prefer modern server names; replace deprecated ones (e.g. tsserver -> ts_ls)
local servers = {
  "bashls",
  "clangd",
  "gopls",
  "nixd",
  "lua_ls",
  "rust_analyzer",
  "marksman",
  "html",
  "astro",
  "tailwindcss",
  "ts_ls",
  "dockerls",
  "cssls",
  "emmet_ls",
  "eslint",
}

-- Only ask Mason to install servers it manages; exclude ones provided by system (e.g., clangd)
local mason_servers = {}
for _, s in ipairs(servers) do
  local d = defs and defs[s]
  if d and d.pkg and not d.no_mason then table.insert(mason_servers, s) end
end
mason_lsp.setup({ ensure_installed = mason_servers, automatic_installation = false })

-- Enhance capabilities for nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

local function on_attach(client, bufnr)
  pcall(lsp_format.on_attach, client, bufnr)
  if vim.lsp.inlay_hint then
    local ih = vim.lsp.inlay_hint
    if type(ih) == "table" and type(ih.enable) == "function" then
      pcall(ih.enable, true, { bufnr = bufnr })
    else
      pcall(ih, bufnr, true)
    end
  end
end

-- Build command from Mason (if available) or fallback to PATH
local registry_ok, registry = pcall(require, "mason-registry")
local function mason_cmd(pkg, bin, args)
  local cmd = { bin }
  if registry_ok then
    local ok, p = pcall(registry.get_package, pkg)
    if ok and p:is_installed() then
      local binpath = p:get_install_path() .. "/bin/" .. bin
      if vim.loop.fs_stat(binpath) then cmd[1] = binpath end
    end
  end
  if type(args) == "table" then
    for _, a in ipairs(args) do table.insert(cmd, a) end
  end
  return cmd
end

-- Simple root finder using marker files
local function find_root(markers, fname)
  markers = markers or { ".git" }
  local startpath = fname or vim.api.nvim_buf_get_name(0)
  startpath = startpath ~= "" and startpath or vim.loop.cwd()
  local dir = vim.fs.dirname(startpath)
  local root_file = vim.fs.find(markers, { path = dir, upward = true })[1]
  return root_file and vim.fs.dirname(root_file) or dir
end

-- Minimal server specs covering common tools
local defs = {
  bashls = {
    pkg = "bash-language-server",
    bin = "bash-language-server",
    args = { "start" },
    filetypes = { "sh" },
    root_markers = { ".git" },
    no_mason = true, -- use system package via Nix instead of Mason
  },
  clangd = {
    bin = "clangd",
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    root_markers = { ".git", "compile_commands.json", "compile_flags.txt" },
  },
  gopls = {
    pkg = "gopls",
    bin = "gopls",
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
  },
  nixd = {
    bin = "nixd",
    filetypes = { "nix" },
    root_markers = { "flake.nix", "shell.nix", "default.nix", ".git" },
    settings = {},
  },
  lua_ls = {
    pkg = "lua-language-server",
    bin = "lua-language-server",
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = { Lua = { telemetry = { enable = false } } },
  },
  rust_analyzer = {
    pkg = "rust-analyzer",
    bin = "rust-analyzer",
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  },
  marksman = {
    pkg = "marksman",
    bin = "marksman",
    args = { "serve" },
    filetypes = { "markdown" },
    root_markers = { ".git" },
  },
  html = {
    pkg = "vscode-langservers-extracted",
    bin = "vscode-html-language-server",
    args = { "--stdio" },
    filetypes = { "html" },
    root_markers = { ".git" },
  },
  astro = {
    pkg = "astro-language-server",
    bin = "astro-ls",
    args = { "--stdio" },
    filetypes = { "astro" },
    root_markers = { "package.json", ".git" },
  },
  tailwindcss = {
    pkg = "tailwindcss-language-server",
    bin = "tailwindcss-language-server",
    args = { "--stdio" },
    filetypes = {
      "html", "css", "scss", "sass", "less",
      "javascript", "javascriptreact", "typescript", "typescriptreact",
      "svelte", "astro", "vue"
    },
    root_markers = { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts", "package.json", ".git" },
  },
  ts_ls = {
    pkg = "typescript-language-server",
    bin = "typescript-language-server",
    args = { "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  },
  dockerls = {
    pkg = "dockerfile-language-server",
    bin = "docker-langserver",
    args = { "--stdio" },
    filetypes = { "dockerfile" },
    root_markers = { ".git" },
  },
  cssls = {
    pkg = "vscode-langservers-extracted",
    bin = "vscode-css-language-server",
    args = { "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { ".git" },
  },
  emmet_ls = {
    pkg = "emmet-ls",
    bin = "emmet-ls",
    args = { "--stdio" },
    filetypes = { "html", "css", "javascriptreact", "typescriptreact", "svelte" },
    root_markers = { ".git" },
  },
  eslint = {
    pkg = "eslint-lsp",
    bin = "vscode-eslint-language-server",
    args = { "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { ".eslintrc", ".eslintrc.json", ".eslintrc.js", "package.json", ".git" },
  },
}

-- Start servers via FileType autocmds
local function setup(server, overrides)
  local d = defs[server] or {}
  local cfg = vim.tbl_deep_extend("force", {
    name = server,
    cmd = mason_cmd(d.pkg, d.bin or server, d.args),
    root_dir = function(fname) return find_root(d.root_markers, fname) end,
    filetypes = d.filetypes,
    capabilities = capabilities,
    on_attach = on_attach,
    settings = d.settings,
  }, overrides or {})

  if not cfg.filetypes or #cfg.filetypes == 0 then return end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = cfg.filetypes,
    callback = function(args)
      vim.lsp.start(cfg, { bufnr = args.buf })
    end,
    desc = "Start LSP server " .. server,
  })
end

-- Per-server tweaks
setup("clangd", { cmd = { "clangd" } })
setup("lua_ls")

-- Defaults for the rest
for _, s in ipairs(servers) do
  if s ~= "clangd" and s ~= "lua_ls" then setup(s) end
end
