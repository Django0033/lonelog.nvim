local M = {}

function M.collect_room_tags(lines)
	local by_id = {}
	for _, line in ipairs(lines) do
		for match in line:gmatch("%[R:[^%]]+%]") do
			local id = match:match("^%[R:([^|]+)")
			if id then
				by_id[id] = match
			end
		end
	end

	local ids = {}
	for id in pairs(by_id) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na < nb
		end
		if na then
			return true
		end
		if nb then
			return false
		end
		return a < b
	end)

	local result = {}
	for _, id in ipairs(ids) do
		table.insert(result, { id = id, raw = by_id[id] })
	end
	return result
end

function M.find_existing_block(lines)
	for i = 1, #lines do
		if lines[i]:match("^=== Dungeon Status ===$") then
			local block_end = i
			for j = i + 1, #lines do
				if lines[j]:match("^===") then
					break
				end
				block_end = j
			end
			return i, block_end
		end
	end
	return nil, nil
end

function M.build_status_block(room_tags)
	local lines = { "=== Dungeon Status ===" }
	for _, tag in ipairs(room_tags) do
		table.insert(lines, tag.raw)
	end
	return lines
end

function M.insert_status_block()
	local buf = 0
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local room_tags = M.collect_room_tags(lines)
	local start_line, end_line = M.find_existing_block(lines)
	local new_lines = M.build_status_block(room_tags)
	if start_line then
		vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, new_lines)
	else
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, new_lines)
	end
end

return M
