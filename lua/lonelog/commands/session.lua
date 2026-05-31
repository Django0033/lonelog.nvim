local M = {}

-- Find the last session number in the buffer by scanning backwards
-- Returns the number found, or 0 if none exists
function M.find_last_session_number(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local max_n = 0
	for _, line in ipairs(lines) do
		local n = line:match("^## Session (%d+)%s*$")
		if n then
			local num = tonumber(n)
			if num and num > max_n then
				max_n = num
			end
		end
	end
	return max_n
end

-- Build a session header template with the given number
function M.build_session_header(number)
	local date = os.date("%Y-%m-%d")
	return {
		"## Session " .. number,
		date,
		"",
		"### Recap",
		"- ",
		"",
		"### Goals",
		"- ",
	}
end

-- Insert a session header at the cursor position
function M.insert_session_header()
	local last_n = M.find_last_session_number()
	local number = last_n + 1
	local lines = M.build_session_header(number)
	local row = vim.fn.line(".") - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, lines)
	-- Position cursor at the first Recap bullet
	vim.api.nvim_win_set_cursor(0, { row + 5, 2 })
end

return M
