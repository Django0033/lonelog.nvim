local M = {}

-- Track all floating windows we create
local active_windows, window_content, window_target_bufnr = {}, {}, {}

-- Pick items using sidebar or vim.ui.select
-- opts: items, format_item, on_select, title
function M.pick(options)
	options = options or {}
	local items = options.items or {}
	local format_item = options.format_item or tostring
	local on_select = options.on_select or function() end

	-- Use sidebar if Telescope is disabled
	if not require("lonelog.config").should_use_telescope() then
		require("lonelog.ui.sidebar").open(options.title or "Select", items, {
			format_item = format_item,
			on_select = on_select,
		})
		return
	end

	-- Use Telescope-compatible vim.ui.select
	vim.ui.select(items, { prompt = options.title or "Select", format_item = format_item }, function(choice)
		if choice then
			on_select(choice)
		end
	end)
end

-- Show result text in floating window
function M.show_result(title, lines, opts)
	opts = opts or {}
	M.close()
	lines = type(lines) == "string" and vim.split(lines, "\n", { trimempty = true }) or lines
	local content = vim.deepcopy(lines)
	local can_insert = M.can_insert_here()
	if title then
		content = vim.list_extend({ title, string.rep("─", 40) }, lines)
	end
	table.insert(content, "")
	table.insert(content, "  Press 'q' to close | 'y' to copy")
	if can_insert then
		table.insert(content, "  Press <CR> to insert")
	end
	return M.open(content, {
		title = opts.title or "Result",
		insert_content = vim.deepcopy(lines),
		target_bufnr = can_insert and vim.api.nvim_get_current_buf() or nil,
	})
end

-- Show result with syntax highlighting for Yes/No/Exceptional
function M.show_colored_result(title, lines, opts)
	opts = opts or {}
	M.close()
	lines = type(lines) == "string" and vim.split(lines, "\n", { trimempty = true }) or lines
	local content, highlights = {}, {}
	if title then
		table.insert(content, title)
	end
	for _, line in ipairs(lines) do
		table.insert(content, line)
		local idx = #content - 1
		if line:match("%[Exceptional") then
			table.insert(highlights, { group = "DiagnosticError", line = idx })
		elseif line:match("%[Yes%]") then
			table.insert(highlights, { group = "DiagnosticOk", line = idx })
		elseif line:match("%[No%]") then
			table.insert(highlights, { group = "DiagnosticWarn", line = idx })
		end
	end
	table.insert(content, "")
	table.insert(content, "  Press 'q' to close | 'y' to copy")
	if M.can_insert_here() then
		table.insert(content, "  Press <CR> to insert")
	end
	local buf = M.open(content, {
		title = title or "Result",
		insert_content = opts.insert_content or vim.deepcopy(lines),
		target_bufnr = vim.api.nvim_get_current_buf(),
	})
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl.group, hl.line, 0, -1)
	end
	return buf
end

-- Show dice roll result
function M.show_dice_result(result)
	local lines = { "", result.display, "" }
	if result.exploding then
		table.insert(lines, "  (exploding dice)")
	end
	return M.show_colored_result("Dice Roll", lines, { insert_content = { result.display } })
end

-- Show oracle result
function M.show_oracle_result(result)
	local display_text
	if result.table == "mythic" then
		local chaos_str = result.chaos_modifier >= 0 and ("+" .. result.chaos_modifier)
			or tostring(result.chaos_modifier)
		display_text = string.format(
			"[%s] (2d10: %d + caos(%s) = %d) %s",
			result.table_name,
			result.dice_total,
			chaos_str,
			result.final,
			result.display
		)
		return M.show_colored_result(
			"Oracle: " .. result.table_name,
			{ "", display_text, "" },
			{ insert_content = { display_text } }
		)
	end
	return M.show_colored_result(
		"Oracle: " .. result.table_name,
		{ "", result.display, "" },
		{ insert_content = { result.display } }
	)
end

-- Get the most recent window content for insertion
function M.get_latest_content()
	for i = #active_windows, 1, -1 do
		local win = active_windows[i]
		if window_content[win] then
			return win, window_content[win]
		end
	end
	return nil, nil
end

-- Copy result to clip board
function M.copy_result(win_id)
	local content = window_content[win_id]

	if not content then
		vim.notify("lonelog: No content to copy", vim.log.levels.WARN)
		return
	end

	local text = table.concat(content, "\n")

	vim.fn.setreg("+", text)
	vim.notify("lonelog: Copied to clipboard", vim.log.levels.INFO)
end

-- Insert result text at cursor position in target buffer
function M.insert_result(win_id)
	local content = window_content[win_id]
	if not content then
		vim.notify("lonelog: No content to insert", vim.log.levels.WARN)
		return
	end
	local target_bufnr = window_target_bufnr[win_id]
	if not target_bufnr then
		vim.notify("lonelog: Could not find target buffer", vim.log.levels.ERROR)
		return
	end
	local target_winid = vim.fn.bufwinid(target_bufnr)
	if target_winid == -1 then
		vim.notify("lonelog: Could not find target window", vim.log.levels.ERROR)
		return
	end

	-- Copy to clipboard
	local text = table.concat(content, "\n")
	vim.fn.setreg("+", text)
	vim.notify("lonelog: Copied to clipboard", vim.log.levels.INFO)

	-- Close floating window
	M.close(win_id)

	-- Change target buffer
	vim.api.nvim_set_current_win(target_winid)

	-- Paste (in normal mode)
	vim.cmd('normal! "+p')
end

-- Check if current buffer is a markdown file (can insert results)
function M.can_insert_here()
	return vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()):match("%.md$") ~= nil
end

-- Open floating window with content
function M.open(content, opts)
	opts = opts or {}
	if type(content) == "string" then
		content = vim.split(content, "\n", { trimempty = true })
	end
	local cfg = require("lonelog.config").get().float
	local width, height = cfg.width, cfg.height
	local win_w, win_h = vim.o.columns, vim.o.lines
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = math.floor(win_w * width),
		height = math.floor(win_h * height),
		row = math.floor((win_h - win_h * height) / 2),
		col = math.floor((win_w - win_w * width) / 2),
		style = "minimal",
		border = cfg.border,
		title = opts.title,
	})
	if opts.focus ~= false then
		vim.api.nvim_set_current_win(win)
	end
	if opts.insert_content then
		window_content[win] = opts.insert_content
	end
	vim.keymap.set("n", "q", function()
		M.close(win)
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "y", function()
		M.copy_result(win)
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "Y", function()
		M.copy_result(win)
	end, { buffer = buf, nowait = true, silent = true })

	if opts.insert_content then
		window_target_bufnr[win] = opts.target_bufnr
		vim.keymap.set("n", "<CR>", function()
			M.insert_result(win)
		end, { buffer = buf, noremap = true, silent = true })
		vim.keymap.set("n", "<Enter>", function()
			M.insert_result(win)
		end, { buffer = buf, noremap = true, silent = true })
	end
	table.insert(active_windows, win)
	return buf, win
end

-- Close specific window or all windows
function M.close(win_id)
	if win_id then
		if vim.api.nvim_win_is_valid(win_id) then
			vim.api.nvim_win_close(win_id, true)
		end
		for i, w in ipairs(active_windows) do
			if w == win_id then
				table.remove(active_windows, i)
				window_content[w] = nil
				window_target_bufnr[w] = nil
				break
			end
		end
	else
		for _, win in ipairs(active_windows) do
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			window_content[win] = nil
			window_target_bufnr[win] = nil
		end
		active_windows = {}
	end
end

return M
