local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Mappings replicated from nixvim config
-- LSP
map("n", "<leader>gd", ":lua vim.lsp.buf.definition()<CR>", opts)
map("n", "<leader>gr", ":lua vim.lsp.buf.references()<CR>", opts)

-- Git and tools (plugins may be absent; mappings retained)
map("n", "<leader>gb", ":GitBlameOpenCommitURL<CR>", opts)
map("n", "<leader>lg", ":LazyGit<CR>", opts)

-- Markdown preview
map("n", "<leader>pm", ":MarkdownPreview<CR>", opts)

-- Telescope
map("n", "<leader>sg", ":Telescope live_grep<CR>", opts)
map("n", "<leader>sb", ":Telescope buffers<CR>", opts)
map("n", "<leader>sc", ":Telescope command_history<CR>", opts)
map("n", "<leader>pf", ":Telescope find_files<CR>", opts)
map("n", "<leader>ql", ":Telescope quickfix<CR>", opts)
map("n", "<leader>u", ":Telescope undo<CR>", opts)

-- File explorer
map("n", "<leader>pv", "<cmd>Ex<CR>", { desc = "Open File Explorer" })

-- Diffview (mapping retained)
map("n", "<leader>do", ":DiffviewOpen<CR>", opts)
map("n", "<leader>dp", ":DiffviewClose<CR>", opts)

-- Macro / visual block passthrough
map("n", "q", "q", opts)
map({"n","x"}, "<C-v>", "<C-v>", opts)

-- Buffers
map("n", "<Tab>", ":BufferNext<CR>", opts)
map("n", "<S-Tab>", ":BufferPrevious<CR>", opts)

-- Alt+1..9: jump to buffer tabs (barbar)
map("n", "<A-1>", ":BufferGoto 1<CR>", opts)
map("n", "<A-2>", ":BufferGoto 2<CR>", opts)
map("n", "<A-3>", ":BufferGoto 3<CR>", opts)
map("n", "<A-4>", ":BufferGoto 4<CR>", opts)
map("n", "<A-5>", ":BufferGoto 5<CR>", opts)
map("n", "<A-6>", ":BufferGoto 6<CR>", opts)
map("n", "<A-7>", ":BufferGoto 7<CR>", opts)
map("n", "<A-8>", ":BufferGoto 8<CR>", opts)
map("n", "<A-9>", ":BufferGoto 9<CR>", opts)

-- Cheat sheet popup: <leader>gg
map("n", "<leader>gg", function()
  local ok, cs = pcall(require, "cheatsheet")
  if ok then
    cs.toggle()
  else
    vim.notify("Cheatsheet-modulen er ikke lastet ennå. Start Neovim på nytt, eller kjør :luafile ~/.config/nvim/lua/cheatsheet.lua", vim.log.levels.WARN)
  end
end, { noremap = true, silent = true, desc = "Cheat sheet popup" })

-- :CheatSheetToggle command
vim.api.nvim_create_user_command("CheatSheetToggle", function()
  local ok, cs = pcall(require, "cheatsheet")
  if ok then
    cs.toggle()
  else
    vim.notify("Cheatsheet-modulen er ikke lastet ennå. Kjør :luafile ~/.config/nvim/lua/cheatsheet.lua", vim.log.levels.WARN)
  end
end, { desc = "Toggle cheatsheet popup" })

-- Splits
map("n", "<leader>s", ":vsplit<CR>", { desc = "Vertical Split", noremap = true, silent = true })
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Trouble (mapping retained)
map("n", "<leader>t", ":Trouble<CR>", opts)

-- DAP (mappings retained)
map("n", "<leader>b", ":DapToggleBreakpoint<CR>", opts)
map("n", "<leader>B", ":DapClearBreakpoints<CR>", opts)
map("n", "<leader>dc", ":DapContinue<CR>", opts)
map("n", "<leader>dso", ":DapStepOver<CR>", opts)
map("n", "<leader>dsi", ":DapStepInto<CR>", opts)
map("n", "<leader>dsO", ":DapStepOut<CR>", opts)
map("n", "<leader>dr", "<cmd>lua require('dap').run_to_cursor()<CR>", opts)
map("n", "<leader>du", "<cmd>lua require('dapui').toggle()<CR>", opts)
map("n", "<leader>dR", "<cmd>lua require('dap').restart()<CR>", opts)
map("n", "<leader>dT", "<cmd>lua require('nvim-dap-virtual-text').refresh()<CR>", opts)

-- QoL: save/quit and clear search
map("n", "<leader>w", ":w<CR>", opts)
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>c", ":nohlsearch<CR>", opts)
