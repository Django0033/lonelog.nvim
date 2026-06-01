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

function M.find_frontmatter_end(lines)
	for i = 1, #lines do
		if lines[i]:match("^---%s*$") then
			for j = i + 1, #lines do
				if lines[j]:match("^---%s*$") then
					return j
				end
			end
		end
	end
	return 0
end

function M.find_existing_block(lines)
	for i = 1, #lines do
		if lines[i]:match("^=== Dungeon Status ===$") then
			for j = i + 1, #lines do
				if lines[j]:match("^===%s*$") then
					return i, j
				end
			end
			return i, i
		end
	end
	return nil, nil
end

function M.get_room_info(room_tags)
	local info_by_id = {}
	for _, tag in ipairs(room_tags) do
		local inner = tag.raw:match("^%[R:(.*)%]$")
		if not inner then
			goto continue
		end
		local fields = {}
		for field in inner:gmatch("([^|]+)") do
			table.insert(fields, field)
		end
		local entry = {}
		if fields[3] and not fields[3]:match("^exits") then
			entry.desc = fields[3]
		end
		for _, field in ipairs(fields) do
			local exits_str = field:match("^exits%s+(.+)$")
			if exits_str then
				entry.exits = {}
				for pair in exits_str:gmatch("([^,]+)") do
					local dir, id = pair:match("^%s*(%a+)%s*:%s*R?(.-)%s*$")
					if dir and id and id ~= "" then
						table.insert(entry.exits, { dir = dir:upper(), id = id })
					end
				end
			end
		end
		info_by_id[tag.id] = entry
		::continue::
	end
	return info_by_id
end

local function walk_forward(id, line_parts, placed, room_info, root_lines, back_lines)
	local info = room_info[id]
	if not info or not info.exits then
		return
	end
	local first_unvisited = true
	for _, exit in ipairs(info.exits) do
		if placed[exit.id] then
			local dest_info = room_info[exit.id]
			local dest_name = dest_info and dest_info.desc or "?"
			table.insert(back_lines, "R" .. id .. " <--" .. exit.dir .. "-- R" .. exit.id .. " (" .. dest_name .. ")")
		else
			placed[exit.id] = true
			local dest_info = room_info[exit.id]
			local arrow = " --" .. exit.dir .. "--> R" .. exit.id
			if dest_info and dest_info.desc then
				arrow = arrow .. " (" .. dest_info.desc .. ")"
			elseif not dest_info then
				arrow = arrow .. " (??? not found)"
			end
			if first_unvisited then
				table.insert(line_parts, arrow)
				walk_forward(exit.id, line_parts, placed, room_info, root_lines, back_lines)
				first_unvisited = false
			else
				local new_parts = { "R" .. id }
				if info.desc then
					table.insert(new_parts, " (" .. info.desc .. ")")
				end
				table.insert(new_parts, arrow)
				walk_forward(exit.id, new_parts, placed, room_info, root_lines, back_lines)
				table.insert(root_lines, table.concat(new_parts))
			end
		end
	end
end

function M.build_ascii_map(room_tags, room_info)
	local placed = {}
	local root_lines = {}
	local back_lines = {}

	for _, tag in ipairs(room_tags) do
		if placed[tag.id] then
			goto continue
		end
		local info = room_info[tag.id]
		placed[tag.id] = true
		if not info.exits or #info.exits == 0 then
			local line = "R" .. tag.id
			if info.desc then
				line = line .. " (" .. info.desc .. ")"
			end
			table.insert(root_lines, line)
			goto continue
		end
		local line_parts = { "R" .. tag.id }
		if info.desc then
			table.insert(line_parts, " (" .. info.desc .. ")")
		end
		walk_forward(tag.id, line_parts, placed, room_info, root_lines, back_lines)
		table.insert(root_lines, table.concat(line_parts))
		::continue::
	end

	if #root_lines == 0 and #back_lines == 0 then
		return {}
	end
	local result = { "--- Map ---" }
	for _, l in ipairs(root_lines) do
		table.insert(result, l)
	end
	for _, l in ipairs(back_lines) do
		table.insert(result, l)
	end
	return result
end

function M.build_status_block(room_tags)
	local room_info = M.get_room_info(room_tags)
	local map_lines = M.build_ascii_map(room_tags, room_info)
	local first_map = #room_tags + 2
	local lines = { "=== Dungeon Status ===" }
	for _, tag in ipairs(room_tags) do
		table.insert(lines, tag.raw)
	end
	for _, line in ipairs(map_lines) do
		table.insert(lines, line)
	end
	table.insert(lines, "===")
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
		local insert_at = M.find_frontmatter_end(lines)
		vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, new_lines)
	end
end

return M
