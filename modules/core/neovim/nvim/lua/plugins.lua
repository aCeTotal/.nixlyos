-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Core dependencies
  { "nvim-lua/plenary.nvim", lazy = true },
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Colorscheme: rose-pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        styles = {
          transparency = true,
          italic = false,
        },
        highlight_groups = {
          -- Treesitter enhancements
          ["@variable"] = { fg = "text" },
          ["@variable.parameter"] = { fg = "iris" },
          ["@variable.member"] = { fg = "foam" },
          ["@property"] = { fg = "foam" },
          ["@function"] = { fg = "rose" },
          ["@function.call"] = { fg = "rose" },
          ["@function.method"] = { fg = "rose" },
          ["@function.method.call"] = { fg = "rose" },
          ["@constructor"] = { fg = "gold" },
          ["@keyword"] = { fg = "pine" },
          ["@keyword.function"] = { fg = "pine" },
          ["@keyword.return"] = { fg = "pine" },
          ["@keyword.operator"] = { fg = "subtle" },
          ["@type"] = { fg = "gold" },
          ["@type.builtin"] = { fg = "gold" },
          ["@constant"] = { fg = "gold" },
          ["@constant.builtin"] = { fg = "love" },
          ["@string"] = { fg = "gold" },
          ["@number"] = { fg = "iris" },
          ["@boolean"] = { fg = "love" },
          ["@operator"] = { fg = "subtle" },
          ["@punctuation.bracket"] = { fg = "muted" },
          ["@punctuation.delimiter"] = { fg = "muted" },
          ["@comment"] = { fg = "muted", italic = true },
          ["@namespace"] = { fg = "iris" },
          ["@include"] = { fg = "pine" },
          ["@tag"] = { fg = "foam" },
          ["@tag.attribute"] = { fg = "iris" },
          ["@tag.delimiter"] = { fg = "muted" },
          -- LSP semantic tokens
          ["@lsp.type.class"] = { fg = "gold" },
          ["@lsp.type.decorator"] = { fg = "iris" },
          ["@lsp.type.enum"] = { fg = "gold" },
          ["@lsp.type.enumMember"] = { fg = "foam" },
          ["@lsp.type.function"] = { fg = "rose" },
          ["@lsp.type.interface"] = { fg = "gold" },
          ["@lsp.type.macro"] = { fg = "iris" },
          ["@lsp.type.method"] = { fg = "rose" },
          ["@lsp.type.namespace"] = { fg = "iris" },
          ["@lsp.type.parameter"] = { fg = "iris" },
          ["@lsp.type.property"] = { fg = "foam" },
          ["@lsp.type.struct"] = { fg = "gold" },
          ["@lsp.type.type"] = { fg = "gold" },
          ["@lsp.type.variable"] = { fg = "text" },
          ["@lsp.mod.deprecated"] = { strikethrough = true },
          ["@lsp.mod.readonly"] = { italic = true },
        },
      })
      vim.cmd.colorscheme("rose-pine")
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSUpdate", "TSUpdateSync" },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if ok then
        ts.setup({
          ensure_installed = {
            "c", "cpp", "lua", "vim", "vimdoc", "query",
            "html", "css", "javascript", "typescript",
            "php", "sql", "bash", "nix", "json", "yaml",
            "markdown", "markdown_inline", "python", "regex",
            "tsx", "rust", "go", "java",
          },
          auto_install = true,
          sync_install = false,
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = "<C-space>",
              node_incremental = "<C-space>",
              scope_incremental = false,
              node_decremental = "<bs>",
            },
          },
        })
      else
        -- Fallback for newer treesitter API
        vim.api.nvim_create_autocmd("FileType", {
          callback = function()
            pcall(vim.treesitter.start)
          end,
        })
      end
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          theme = "rose-pine",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Buffer tabs
  {
    "romgrk/barbar.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "BufAdd",
    opts = {
      animation = false,
      auto_hide = false,
      tabpages = true,
    },
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = { horizontal = { prompt_position = "top" } },
        },
      })
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "undo")
    end,
  },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
  { "debugloop/telescope-undo.nvim", lazy = true },

  -- CMP (autocompletion)
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer", keyword_length = 3 },
          { name = "path" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
        }),
      })

      -- Cmdline completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },

  -- LSP config loader (using native vim.lsp.config API in Neovim 0.11+)
  {
    "hrsh7th/cmp-nvim-lsp",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("lsp")
    end,
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },
  { "f-person/git-blame.nvim", cmd = "GitBlameOpenCommitURL" },
  { "kdheepak/lazygit.nvim", cmd = "LazyGit" },
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewClose" } },

  -- Trouble (diagnostics)
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = {
      indent = { char = "▏" },
      scope = { enabled = true },
    },
  },

  -- Auto-pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle" },
      { "gc", mode = { "n", "v" }, desc = "Comment toggle" },
    },
    config = true,
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  -- DAP (debugging)
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>b", "<cmd>DapToggleBreakpoint<cr>", desc = "Toggle Breakpoint" },
      { "<leader>dc", "<cmd>DapContinue<cr>", desc = "Continue" },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    keys = { { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" } },
    config = function()
      require("dapui").setup()
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
  },

  -- Which-key (keybinding hints)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Start screen
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
        "",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
        dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
        dashboard.button("g", "  Grep text", ":Telescope live_grep<CR>"),
        dashboard.button("c", "  Config", ":e ~/.config/nvim/init.lua<CR>"),
        dashboard.button("q", "  Quit", ":qa<CR>"),
      }
      alpha.setup(dashboard.config)
    end,
  },
})
