local M = {}

function M.build_combat_block()
	return { "[COMBAT]", "", "[/COMBAT]" }
end

function M.insert_combat_block()
	local lines = M.build_combat_block()
	local row = vim.fn.line(".") - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, lines)
	vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
	vim.cmd("startinsert!")
end

return M
