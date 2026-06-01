local M = {}

function M.find_combat_block(lines, cursor_row)
	local start_line, end_line

	for i, line in ipairs(lines) do
		if line:match("^%[COMBAT%]$") then
			start_line = i
		elseif line:match("^%[/COMBAT%]$") then
			if start_line and cursor_row >= start_line and cursor_row <= i then
				return start_line, i
			end
			start_line = nil
		end
	end

	return nil, nil
end

function M.find_highest_round(lines, start, finish)
	local highest = 0

	for i = start, finish do
		local round = lines[i]:match("^R(%d+)")
		if round then
			local n = tonumber(round)
			if n and n > highest then
				highest = n
			end
		end
	end

	return highest
end

function M.collect_roster(lines, start, finish)
	local roster = {}

	for i = start, finish do
		local pc_name, pc_hp = lines[i]:match("%[PC:([^|]+)%|HP (%d+)")
		if pc_name then
			table.insert(roster, { type = "PC", name = pc_name, hp = tonumber(pc_hp) })
		end

		local foe_name, foe_hp = lines[i]:match("%[F:([^|]+)%|HP (%d+)")
		if foe_name then
			table.insert(roster, { type = "F", name = foe_name, hp = tonumber(foe_hp) })
		end
	end

	return roster
end

function M.build_roster_line(round_num, roster)
	local parts = {}
	for _, entry in ipairs(roster) do
		table.insert(parts, string.format("[%s:%s|HP %d]", entry.type, entry.name, entry.hp))
	end

	local tags_str = table.concat(parts, " ")
	return string.format("R%d Roster: %s", round_num, tags_str)
end

function M.insert_round(with_roster)
	local buf = 0
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local cursor_row = vim.fn.line(".")

	local start_line, end_line = M.find_combat_block(lines, cursor_row)
	if not start_line then
		vim.notify("lonelog: No combat block found", vim.log.levels.WARN)
		return
	end

	local highest = M.find_highest_round(lines, start_line, end_line)
	local round_num = highest + 1

	local insert_row = cursor_row - 1

	if with_roster then
		local roster = M.collect_roster(lines, start_line, end_line)
		local roster_line = M.build_roster_line(round_num, roster)
		vim.api.nvim_buf_set_lines(buf, insert_row, insert_row, false, { roster_line })
		vim.api.nvim_win_set_cursor(0, { cursor_row, #roster_line })
	else
		local round_text = "R" .. round_num
		vim.api.nvim_buf_set_lines(buf, insert_row, insert_row, false, { round_text })
		vim.api.nvim_win_set_cursor(0, { cursor_row, #round_text })
	end

	vim.cmd("startinsert!")
end

return M
