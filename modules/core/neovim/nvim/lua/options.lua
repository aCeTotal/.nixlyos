local g = vim.g
local opt = vim.opt

-- Leader and provider toggles
g.mapleader = " "
g.maplocalleader = ","
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_python_provider = 0 -- python2

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
-- Keep a single sign column; add spacing after numbers via statuscolumn instead
opt.signcolumn = "yes"
opt.numberwidth = 4

-- Add extra space between line numbers and code (not at screen edge)
-- Requires Neovim 0.9+
if vim.fn.has("nvim-0.9") == 1 or vim.fn.has("nvim-0.10") == 1 or vim.fn.has("nvim-0.11") == 1 then
  -- signs (%s) + relative/absolute line number + two spaces + (optional) fold column
  -- use Vimscript ternary, not Lua's and/or, inside %{}
  vim.o.statuscolumn = "%s%{v:relnum ? v:relnum : v:lnum}   %C"
end
opt.showtabline = 4

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true
opt.wrap = false
opt.hidden = true
opt.mouse = 'a'

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

-- Splits and scrolling
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Performance and UX
opt.updatetime = 100
opt.timeoutlen = 300
opt.completeopt = { "menuone", "noselect", "noinsert" }
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.cmdheight = 0
opt.showmode = false

-- Folding (ufo-friendly baseline)
opt.foldcolumn = "0"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Clipboard
opt.clipboard = "unnamedplus"
