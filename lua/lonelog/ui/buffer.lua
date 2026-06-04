-- Utility to open a vertical split buffer with selectable items

local M = {}

function M.open(lines, opts)
	opts = opts or {}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	vim.cmd("botright vnew")
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_win_set_width(0, opts.width or 40)
	vim.api.nvim_buf_set_name(buf, opts.title or "Lonelog")

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end, { buffer = buf, nowait = true, silent = true })

	if opts.on_select then
		vim.keymap.set("n", "<CR>", function()
			local line = vim.fn.line(".")
			if line < 1 or line > #(opts.items or lines) then return end
			vim.api.nvim_win_close(0, true)
			opts.on_select((opts.items or lines)[line])
		end, { buffer = buf, nowait = true, silent = true })
	end

	return buf
end

function M.open_items(items, format_fn, on_select, title)
	local lines = {}
	for _, item in ipairs(items) do
		local display = format_fn(item):gsub("\n.*$", " [...]")
		table.insert(lines, "  " .. display)
	end
	return M.open(lines, {
		title = title,
		items = items,
		width = 50,
		on_select = on_select,
	})
end

function M.open_group_browser(opts)
	local lines = { "  " .. opts.title, "" }
	local group_info = {}
	for _, g in ipairs(opts.groups) do
		table.insert(lines, "    " .. g.label)
		table.insert(group_info, { name = g.name, items = g.items })
	end
	table.insert(lines, "")
	table.insert(lines, "  <CR> select group    q close")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	vim.cmd("botright vnew")
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_win_set_width(0, 40)
	vim.api.nvim_buf_set_name(buf, opts.title)

	vim.keymap.set("n", "<CR>", function()
		local idx = vim.fn.line(".") - 2
		if idx < 0 or idx >= #group_info then return end
		local group = group_info[idx]
		local items = group.items
		if opts.group_filter and #items > 0 then
			local query = vim.fn.input("Search " .. group.name .. ": ")
			if query and query ~= "" then
				items = opts.group_filter(items, query)
				if #items == 0 then
					vim.notify("No tags match")
					return
				end
			end
		end
		vim.api.nvim_win_close(0, true)
		M.open_items(items, opts.format_item, function(item)
			opts.on_select(item)
		end, group.name)
	end, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end, { buffer = buf, nowait = true, silent = true })
end

return M
