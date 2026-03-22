local M = {
  win_id = nil,   -- ID of the sidebar window
  buf_id = nil,   -- ID of the sidebar buffer
  items = {},     -- Display items
  data = {},      -- Original data objects (may differ from items)
  on_select = nil, -- Callback when item is selected
}

-- Close sidebar window and reset state
local function cleanup()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
  end
  M.win_id = nil
  M.buf_id = nil
  M.items = {}
  M.data = {}
  M.on_select = nil
end

-- Close sidebar (called by user pressing q)
function M.close()
  cleanup()
end

-- Open sidebar with list of items
-- opts:
--   title: Header title
--   items: List of display items
--   data: Original data (defaults to items)
--   format_item: Function(item, index) -> string to format display
--   on_select: Function(item) called when user selects
function M.open(title, items, opts)
  opts = opts or {}
  cleanup()

  M.items = items
  M.data = opts.data or items
  M.on_select = opts.on_select

  local cfg = require("lonelog.config").get().sidebar
  local width = cfg.width or 50
  local height = math.min(#items + 4, vim.o.lines - 4)

  -- Create new buffer (no file, scratch buffer)
  M.buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.buf_id, "bufhidden", "wipe")

  -- Build content lines
  local lines = {}
  if title then table.insert(lines, title) end
  table.insert(lines, string.rep("─", width - 2))
  for i, item in ipairs(items) do
    local label = opts.format_item and opts.format_item(item, i) or tostring(item)
    table.insert(lines, string.format(" %2d │ %s", i, label))
  end
  table.insert(lines, string.rep("─", width - 2))
  table.insert(lines, "   │ j/k: move  Enter: select  q: close")

  vim.api.nvim_buf_set_lines(M.buf_id, 0, -1, false, lines)
  vim.api.nvim_buf_add_highlight(M.buf_id, -1, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(M.buf_id, -1, "NonText", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(M.buf_id, -1, "NonText", #lines - 2, 0, -1)

  -- Open window on right side of editor
  M.win_id = vim.api.nvim_open_win(M.buf_id, true, {
    relative = "editor",
    width = width,
    height = height,
    row = 1,
    col = vim.o.columns - width - 1,
    style = "minimal",
    border = "rounded",
    title = " Lonelog ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(M.win_id, "cursorline", true)
  vim.api.nvim_win_set_cursor(M.win_id, { 3, 2 })

  -- Handle selection: get current cursor position, find corresponding item
  local function select_current()
    local cursor = vim.api.nvim_win_get_cursor(M.win_id)
    local idx = cursor[1] - 2  -- Convert line number to index (accounting for header lines)
    if idx >= 1 and idx <= #M.data then
      local item = M.data[idx]
      local callback = M.on_select  -- Store callback before cleanup
      cleanup()                     -- Close window first
      if callback then callback(item) end  -- Then call callback (may open new window)
    end
  end

  -- Set up keybindings
  vim.keymap.set("n", "q", function() M.close() end, { buffer = M.buf_id, nowait = true })
  vim.keymap.set("n", "<Esc>", function() M.close() end, { buffer = M.buf_id, nowait = true })
  vim.keymap.set("n", "<CR>", select_current, { buffer = M.buf_id, nowait = true })
  vim.keymap.set("n", "<Enter>", select_current, { buffer = M.buf_id, nowait = true })
  vim.keymap.set("n", "j", function()
    local c = vim.api.nvim_win_get_cursor(M.win_id)
    if c[1] < #M.items + 2 then vim.api.nvim_win_set_cursor(M.win_id, { c[1] + 1, c[2] }) end
  end, { buffer = M.buf_id, nowait = true })
  vim.keymap.set("n", "k", function()
    local c = vim.api.nvim_win_get_cursor(M.win_id)
    if c[1] > 3 then vim.api.nvim_win_set_cursor(M.win_id, { c[1] - 1, c[2] }) end
  end, { buffer = M.buf_id, nowait = true })

  -- Clean up if window is closed externally
  vim.api.nvim_create_autocmd("WinClosed", { buffer = M.buf_id, callback = cleanup, once = true })

  return M.buf_id, M.win_id
end

-- Check if sidebar is currently open
function M.is_open()
  return M.win_id ~= nil and vim.api.nvim_win_is_valid(M.win_id)
end

return M
