local M = {}

function M.parse_exits(raw_tag)
	local inner = raw_tag:match("^%[R:(.*)%]$")
	if not inner then
		return {}
	end

	for field in inner:gmatch("([^|]+)") do
		local exits_str = field:match("^exits%s+(.+)$")
		if exits_str then
			local result = {}
			for pair in exits_str:gmatch("([^,]+)") do
				local dir, id = pair:match("^%s*(%a+)%s*:%s*R?(.-)%s*$")
				if dir and id and id ~= "" then
					table.insert(result, { dir = dir:upper(), id = id })
				end
			end
			return result
		end
	end
	return {}
end

function M.find_room_tag_on_line(line)
	return line:match("%[R:[^%]]+%]")
end

function M.collect_room_data(lines)
	local by_id = {}
	for ln, line in ipairs(lines) do
		local raw = M.find_room_tag_on_line(line)
		if raw then
			local id = raw:match("^%[R:([^|]+)")
			if id then
				by_id[id] = {
					line = ln,
					raw = raw,
					exits = M.parse_exits(raw),
				}
			end
		end
	end
	return by_id
end

function M.navigate_to_room()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cur_line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not cur_line then
		return
	end

	local raw = M.find_room_tag_on_line(cur_line)
	if not raw then
		vim.notify("lonelog: No room tag found at cursor", vim.log.levels.INFO)
		return
	end

	local exits = M.parse_exits(raw)
	if #exits == 0 then
		vim.notify("lonelog: No exits defined for this room", vim.log.levels.INFO)
		return
	end

	local room_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local rooms = M.collect_room_data(room_lines)

	local choices = {}
	for _, exit in ipairs(exits) do
		local label = exit.dir .. " -> R" .. exit.id
		local target = rooms[exit.id]
		if target then
			local desc = target.raw:match("^%[R:[^||]*|([^%]]*)") or ""
			label = label .. " (" .. desc .. ")"
		end
		table.insert(choices, {
			label = label,
			exit = exit,
			target = target,
		})
	end

	vim.ui.select(choices, {
		prompt = "Navigate to room:",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		if not choice.target then
			vim.notify("lonelog: Room R:" .. choice.exit.id .. " not found in buffer", vim.log.levels.WARN)
			return
		end
		vim.api.nvim_win_set_cursor(0, { choice.target.line, 0 })
		vim.cmd("normal! zz")
	end)
end

return M
