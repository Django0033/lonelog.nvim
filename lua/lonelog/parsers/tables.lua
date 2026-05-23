local M = {}

function M.parse_tables(lines)
	local result = {}
	local current = nil

	for _, line in ipairs(lines) do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed == "" then
			goto continue
		end

		local header = M.parse_header(trimmed)
		if header and header.dice then
			current = { name = header.name, dice = header.dice, entries = {} }
			result[header.name:lower()] = current
			if header.options then
				for idx, opt in ipairs(header.options) do
					table.insert(current.entries, { min = idx, max = idx, text = opt })
				end
				current = nil
			end
			goto continue
		end
		if header and not header.dice then
			current = { name = header.name, dice = nil, entries = {} }
			result[header.name:lower()] = current
			goto continue
		end

		if current and line:match("^%s+") then
			local min, max, text = trimmed:match("^(%d+)%s*%-%s*(%d+)%s*:%s*(.+)$")
			if not min then
				min, text = trimmed:match("^(%d+)%s*:%s*(.+)$")
				if min then
					max = min
				end
			end
			if min and text then
				table.insert(current.entries, {
					min = tonumber(min),
					max = tonumber(max or min),
					text = text:match("^%s*(.-)%s*$"),
				})
			end
			goto continue
		end

		if current then
			current = nil
		end

		::continue::
	end

	return result
end

function M.resolve_entry(table_def, value)
	for _, entry in ipairs(table_def.entries) do
		if value >= entry.min and value <= entry.max then
			return entry.text
		end
	end
	return nil
end

function M.parse_roll_line(line)
	local _, _, rest, value = line:find("^%s*tbl:%s*(.-)%s*=%s*([+-]?%d+)")
	if not rest then
		return nil
	end
	local dice = rest:match("(%d*[dD][%d]+)%s*$")
	local name = dice and rest:match("(.-)%s*%d*[dD][%d]+%s*$") or rest
	name = name:match("^%s*(.-)%s*$"):lower()
	return { name = name, value = tonumber(value) }
end

function M.parse_header(line)
	local trimmed = line:match("^%s*(.-)%s*$")
	if not trimmed then
		return nil
	end

	local _, _, name, dice = trimmed:find("^%s*tbl:%s*([^%(%[]+)%(([^%)]+)%)%s*$")
	if name then
		name = name:match("^%s*(.-)%s*$")
		dice = dice:match("^%s*(.-)%s*$")
		return { name = name, dice = dice, options = nil }
	end

	local _, _, name, bracket_content = trimmed:find("^%s*tbl:%s*([^%(%[]+)%[([^%]]+)%]%s*$")
	if name then
		name = name:match("^%s*(.-)%s*$")
		local opts = {}
		for w in bracket_content:gmatch("[^,]+") do
			table.insert(opts, w:match("^%s*(.-)%s*$"))
		end
		return { name = name, dice = "d" .. #opts, options = opts }
	end

	local plain_name = trimmed:match("^%s*tbl:%s*(.+)$")
	if plain_name then
		return { name = plain_name:match("^%s*(.-)%s*$"), dice = nil, options = nil }
	end

	return nil
end

return M
