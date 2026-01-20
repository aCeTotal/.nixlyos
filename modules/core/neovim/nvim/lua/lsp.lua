-- LSP Configuration (Neovim 0.11+ API)

-- Enhanced capabilities for nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- Enable semantic tokens for better highlighting
capabilities.textDocument.semanticTokens = {
  dynamicRegistration = false,
  tokenTypes = {
    "namespace", "type", "class", "enum", "interface", "struct",
    "typeParameter", "parameter", "variable", "property", "enumMember",
    "event", "function", "method", "macro", "keyword", "modifier",
    "comment", "string", "number", "regexp", "operator", "decorator",
  },
  tokenModifiers = {
    "declaration", "definition", "readonly", "static", "deprecated",
    "abstract", "async", "modification", "documentation", "defaultLibrary",
  },
  formats = { "relative" },
  requests = { range = true, full = { delta = true } },
  multilineTokenSupport = false,
  overlappingTokenSupport = true,
}

-- LSP keymaps via LspAttach autocmd
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    -- Navigation
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)

    -- Documentation
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

    -- Actions
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts)

    -- Diagnostics
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, opts)
  end,
})

-- Diagnostic configuration (Neovim 0.11+ API)
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
  },
})

-- LSP hover/signature borders
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

-- Server configurations
local servers = {
  -- C/C++
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
      "--query-driver=/nix/store/*/bin/gcc,/nix/store/*/bin/g++,/nix/store/*/bin/clang,/nix/store/*/bin/clang++",
    },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
      fallbackFlags = { "-std=c++20", "-Wall" },
    },
    root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", "Makefile", ".git" },
  },

  -- HTML
  html = {
    filetypes = { "html", "htmldjango", "php" },
  },

  -- CSS
  cssls = {},

  -- JavaScript/TypeScript
  ts_ls = {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },

  -- PHP
  phpactor = {},

  -- Python
  pyright = {},

  -- Lua (for Neovim config)
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  },

  -- Nix
  nil_ls = {
    settings = {
      ["nil"] = {
        formatting = { command = { "nixpkgs-fmt" } },
      },
    },
  },

  -- Bash
  bashls = {},

  -- JSON
  jsonls = {},

  -- YAML
  yamlls = {},
}

-- Setup all servers using vim.lsp.config (Neovim 0.11+ API)
for server, config in pairs(servers) do
  config.capabilities = capabilities
  vim.lsp.config(server, config)
end

-- Enable all configured servers
vim.lsp.enable(vim.tbl_keys(servers))

-- Generate .clangd config with NixOS include paths
local function generate_clangd_config(root)
  if vim.fn.filereadable(root .. "/.clangd") == 1 then
    return
  end

  local handle = io.popen("echo | gcc -E -Wp,-v -xc - 2>&1 | grep '^ /' | head -20")
  if not handle then return end
  local output = handle:read("*a")
  handle:close()

  local includes = {}
  for path in output:gmatch("(%S+)") do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(includes, '    - "-I' .. path .. '"')
    end
  end

  if #includes == 0 then return end

  local config = "# Auto-generated for NixOS\nCompileFlags:\n  Add:\n" .. table.concat(includes, "\n") .. "\n"

  local file = io.open(root .. "/.clangd", "w")
  if file then
    file:write(config)
    file:close()
    vim.notify(".clangd generated", vim.log.levels.INFO)
  end
end

-- Auto-generate compile_commands.json for C/C++ projects
local function generate_compile_commands(root, callback)
  local cmd = nil

  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
    cmd = "cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build && ln -sf build/compile_commands.json ."
  elseif vim.fn.filereadable(root .. "/meson.build") == 1 then
    cmd = "meson setup build --wipe 2>/dev/null || meson setup build && ln -sf build/compile_commands.json ."
  elseif vim.fn.filereadable(root .. "/Makefile") == 1 then
    cmd = "bear -- make -n 2>/dev/null || bear -- make clean all 2>/dev/null || bear -- make"
  else
    return false
  end

  vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)
  vim.fn.jobstart(cmd, {
    cwd = root,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("compile_commands.json generated!", vim.log.levels.INFO)
        if callback then callback() end
      else
        vim.notify("Failed to generate compile_commands.json", vim.log.levels.WARN)
      end
    end,
  })
  return true
end

-- Auto-generate on entering C/C++ buffer
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    local root = vim.fn.getcwd()
    generate_clangd_config(root)
    if vim.fn.filereadable(root .. "/compile_commands.json") == 0
       and vim.fn.filereadable(root .. "/build/compile_commands.json") == 0 then
      generate_compile_commands(root, function()
        vim.schedule(function() vim.cmd("LspRestart clangd") end)
      end)
    end
  end,
  once = true,
})

-- Command to generate compile_commands.json for C/C++ projects
vim.api.nvim_create_user_command("GenerateCompileCommands", function()
  local root = vim.fn.getcwd()
  local cmd = nil

  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
    cmd = "cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build && ln -sf build/compile_commands.json ."
  elseif vim.fn.filereadable(root .. "/meson.build") == 1 then
    cmd = "meson setup build --wipe 2>/dev/null || meson setup build && ln -sf build/compile_commands.json ."
  elseif vim.fn.filereadable(root .. "/Makefile") == 1 then
    cmd = "bear -- make -n || bear -- make"
  else
    vim.notify("No build system found (CMake, Meson, or Makefile)", vim.log.levels.WARN)
    return
  end

  vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)
  vim.fn.jobstart(cmd, {
    cwd = root,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("compile_commands.json generated! Restarting LSP...", vim.log.levels.INFO)
        vim.schedule(function()
          vim.cmd("LspRestart")
        end)
      else
        vim.notify("Failed to generate compile_commands.json", vim.log.levels.ERROR)
      end
    end,
  })
end, { desc = "Generate compile_commands.json and restart LSP" })

-- Command to regenerate .clangd config
vim.api.nvim_create_user_command("GenerateClangd", function()
  local root = vim.fn.getcwd()
  -- Delete existing to force regeneration
  vim.fn.delete(root .. "/.clangd")
  generate_clangd_config(root)
  vim.cmd("LspRestart clangd")
end, { desc = "Regenerate .clangd config with NixOS include paths" })
