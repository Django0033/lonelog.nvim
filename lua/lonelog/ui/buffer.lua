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

return M
