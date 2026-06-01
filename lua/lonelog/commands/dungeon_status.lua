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

function M.parse_tag_info(raw_tag)
	local inner = raw_tag:match("^%[R:(.*)%]$")
	if not inner then
		return nil
	end
	local fields = {}
	for field in inner:gmatch("([^|]+)") do
		table.insert(fields, field)
	end
	local info = { id = fields[1] or "" }
	if fields[3] and not fields[3]:match("^exits") then
		info.desc = fields[3]
	end
	for _, field in ipairs(fields) do
		local exits_str = field:match("^exits%s+(.+)$")
		if exits_str then
			info.exits = {}
			for pair in exits_str:gmatch("([^,]+)") do
				local dir, id = pair:match("^%s*(%a+)%s*:%s*R?(.-)%s*$")
				if dir and id and id ~= "" then
					table.insert(info.exits, { dir = dir:upper(), id = id })
				end
			end
		end
	end
	return info
end

function M.build_annotation(raw_tag, desc_by_id)
	local info = M.parse_tag_info(raw_tag)
	if not info or not info.exits or #info.exits == 0 then
		return ""
	end
	local parts = {}
	for _, exit in ipairs(info.exits) do
		local dest_desc = desc_by_id[exit.id] or "?"
		table.insert(parts, exit.dir .. " → R" .. exit.id .. " (" .. dest_desc .. ")")
	end
	return "  → " .. table.concat(parts, " │ ")
end

function M.build_status_block(room_tags)
	local desc_by_id = {}
	for _, tag in ipairs(room_tags) do
		local info = M.parse_tag_info(tag.raw)
		if info and info.desc then
			desc_by_id[info.id] = info.desc
		end
	end
	local lines = { "=== Dungeon Status ===" }
	for _, tag in ipairs(room_tags) do
		local annotation = M.build_annotation(tag.raw, desc_by_id)
		table.insert(lines, tag.raw .. annotation)
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
