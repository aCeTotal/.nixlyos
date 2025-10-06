local M = {}

local state = { win = nil, buf = nil }

local content = {
  "Vim quick motions + grep",
  "",
  "Motions",
  "  w/b   next/prev word",
  "  e/ge  end of word (fwd/back)",
  "  0/^/$ line start/first non-blank/end",
  "  gg/G  top/end of file",
  "  f{c}/t{c} find/till char; ;/, to repeat",
  "  %     jump to matching pair",
  "  }/{   next/prev paragraph/block",
  "  H/M/L top/middle/low of screen",
  "  Ctrl-o/Ctrl-i older/newer jump",
  "",
  "Objects (inside/around)",
  "  ciw/diw/yiw change/delete/yank inner word",
  "  ci\"/di\" change/delete inside quotes",
  "  ca)/da) change/delete around parens",
  "",
  "Editing",
  "  x/X   delete char (fwd/back)",
  "  dd/yy/cc delete/yank/change line",
  "  u/Ctrl-r undo/redo",
  "  =/==  indent selection/line",
  "",
  "Search",
  "  /pat   forward search (n/N to next/prev)",
  "  ?pat   backward search (n/N)",
  "  *      search word under cursor",
  "  :%s/old/new/gc  confirm replace in file",
  "",
  "Grep",
  "  <leader>sg  Telescope live_grep",
  "  <leader>pf  Telescope find_files",
  "  :grep PATTERN | :copen (ripgrep)",
  "",
  "LSP (if enabled)",
  "  <leader>gd  goto definition",
  "  <leader>gr  references",
  "  K         hover",
}

local function calc_dimensions(lines)
  local maxw = 0
  for _, l in ipairs(lines) do maxw = math.max(maxw, #l) end
  local width = math.min(vim.o.columns - 4, maxw + 4)
  local height = math.min(vim.o.lines - 4, #lines + 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  return width, height, row, col
end

local function create_window()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, content)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })

  local width, height, row, col = calc_dimensions(content)
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = row,
    col = col,
    zindex = 200,
  })

  -- Close bindings (buffer-local)
  local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      pcall(vim.api.nvim_win_close, state.win, true)
    end
    state.win, state.buf = nil, nil
  end
  vim.keymap.set("n", "q", close, { buffer = state.buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = state.buf, nowait = true, silent = true })
  vim.keymap.set("n", "<CR>", close, { buffer = state.buf, nowait = true, silent = true })

  -- Autoclose on BufLeave
  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    buffer = state.buf,
    once = true,
    callback = close,
  })
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then return end
  create_window()
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  state.win, state.buf = nil, nil
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

return M
