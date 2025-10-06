-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Core libs
  { "nvim-lua/plenary.nvim" },
  { "nvim-tree/nvim-web-devicons" },

  -- Colorscheme: rose-pine (moon), transparent bg
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        styles = { transparency = true, italic = false },
      })
      vim.cmd.colorscheme("rose-pine")
      -- re-enforce colorscheme when others try to change it
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function(args)
          if args.match ~= "rose-pine" then
            vim.schedule(function() vim.cmd.colorscheme("rose-pine") end)
          end
        end,
        desc = "Force rose-pine colorscheme",
      })
    end,
  },

  -- Transparent windows
  {
    "xiyaowong/transparent.nvim",
    config = function() require("transparent").setup({}) end,
  },

  -- Statusline (with active LSP name)
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local function lsp_name()
        local buf_ft = vim.bo.filetype
        for _, client in ipairs(vim.lsp.get_active_clients()) do
          local filetypes = client.config.filetypes
          if filetypes and vim.tbl_contains(filetypes, buf_ft) then
            return client.name
          end
        end
        return ""
      end
      require("lualine").setup({
        options = {
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = { "filename", "diff" },
          lualine_x = { "diagnostics", { lsp_name, icon = "" }, "encoding", "fileformat", "filetype" },
        },
      })
    end,
  },

  -- Telescope + fzf + undo picker
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = { horizontal = { prompt_position = "top" } },
        },
        pickers = { colorscheme = { enable_preview = true } },
      })
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "undo")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
  { "debugloop/telescope-undo.nvim" },

  -- Treesitter + refactor
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Robust installer settings for NixOS: prefer git, allow multiple compilers
      local ts_install = require("nvim-treesitter.install")
      ts_install.prefer_git = true
      ts_install.compilers = { "clang", "gcc" }

      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          -- Core/system
          "bash", "c", "cpp", "lua", "nix", "vim", "vimdoc", "query",
          -- Infra / markup
          "json", "jsonc", "yaml", "toml", "ini", "dockerfile", "make", "regex",
          -- Web
          "html", "css", "javascript", "typescript", "tsx", "svelte", "astro",
          -- Dev
          "go", "rust", "python", "cmake",
          -- Docs
          "markdown", "markdown_inline",
        },
        ignore_install = { "ipkg" },
        auto_install = false,
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  { "nvim-treesitter/nvim-treesitter-refactor", config = function()
      require("nvim-treesitter.configs").setup({
        refactor = { highlight_definitions = { enable = true, clear_on_cursor_move = false } },
      })
    end },

  -- Comment
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        toggler = { line = "<C-b>" },
        opleader = { line = "<C-b>" },
      })
    end,
  },

  -- Auto-save and auto-close
  { "Pocco81/auto-save.nvim", config = true },
  { "m4xshen/autoclose.nvim", config = true },

  -- Open links with gx
  { "chrishrb/gx.nvim", config = true },

  -- Start screen
  {
    "mhinz/vim-startify",
    config = function()
      vim.g.startify_change_to_dir = 0
      vim.g.startify_use_unicode = 1
      vim.g.startify_files_number = 30
      vim.g.startify_lists = { { type = "dir", header = { "   Files" } } }
      vim.g.startify_skiplist = { "flake.lock" }
      vim.g.startify_custom_header = {
        "",
        "     ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗",
        "     ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║",
        "     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║",
        "     ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║",
        "     ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "     ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
      }
    end,
  },

  -- CMP and friends
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        experimental = { ghost_text = true },
        performance = { debounce = 60, fetching_timeout = 200, max_view_entries = 30 },
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        formatting = { fields = { "kind", "abbr", "menu" } },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "emoji" },
          { name = "buffer", option = { get_bufnrs = vim.api.nvim_list_bufs }, keyword_length = 3 },
          { name = "path", keyword_length = 3 },
          { name = "luasnip", keyword_length = 3 },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
          end, { "i", "s" }),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<S-CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        }),
      })

      -- Cmdline sources
      cmp.setup.cmdline({"/", "?"}, { sources = { { name = "buffer" } } })
      cmp.setup.cmdline(":", { sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }) })
    end,
  },

  -- LSP stack (no lspconfig framework; use vim.lsp.start)
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "lukas-reineke/lsp-format.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function() require("lsp") end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = { indent = { char = "▎" } },
  },

  -- Extra plugins required by keymaps present in config
  { "folke/trouble.nvim", opts = {} },
  { "sindrets/diffview.nvim" },
  { "f-person/git-blame.nvim" },
  { "kdheepak/lazygit.nvim" },
  { "romgrk/barbar.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "iamcco/markdown-preview.nvim", build = function() vim.fn["mkdp#util#install"]() end },

  -- DAP stack for keymaps
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" }, config = function()
      require("dapui").setup()
    end },
  { "theHamsta/nvim-dap-virtual-text", dependencies = { "mfussenegger/nvim-dap" }, opts = {} },
})
