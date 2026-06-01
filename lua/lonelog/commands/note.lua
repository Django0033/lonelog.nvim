local M = {}

function M.build_note()
	return "(note: )"
end

function M.insert_note()
	local text = M.build_note()
	local row = vim.fn.line(".") - 1
	local col = vim.fn.col(".") - 1
	local line = vim.api.nvim_get_current_line()
	local before = line:sub(1, col)
	local after = line:sub(col + 1)
	vim.api.nvim_set_current_line(before .. text .. after)
	vim.api.nvim_win_set_cursor(0, { row + 1, col + 7 })
end

return M
