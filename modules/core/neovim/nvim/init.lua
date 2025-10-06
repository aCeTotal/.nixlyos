-- Neovim config: pure Lua, distro-agnostic

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Core options and keymaps
require("options")
require("keymaps")

-- Plugin manager + plugins (lazy.nvim)
require("plugins")

-- Preload local cheatsheet module so mappings work immediately
pcall(require, "cheatsheet")
