local g = vim.g
local opt = vim.opt

-- Leader
g.mapleader = " "
g.maplocalleader = ","

-- Disable unused providers
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_python_provider = 0

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.wrap = false
opt.mouse = "a"

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Splits
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8

-- Performance
opt.updatetime = 250
opt.swapfile = false
opt.undofile = true

-- Clipboard
opt.clipboard = "unnamedplus"
