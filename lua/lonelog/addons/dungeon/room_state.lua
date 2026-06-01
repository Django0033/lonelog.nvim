local ALL_STATES = {
	"unexplored", "active", "cleared", "looted",
	"locked", "trapped", "safe", "collapsed",
}

local M = {}

function M.parse_states(raw_tag)
	local state_str = raw_tag:match("^%[R:[^|]+|([^|%]]+)")
	if not state_str or state_str == "" then
		return { "unexplored" }
	end
	local states = {}
	for s in state_str:gmatch("([^,]+)") do
		table.insert(states, s)
	end
	if #states == 0 then
		return { "unexplored" }
	end
	return states
end

function M.build_tag(raw_tag, new_states)
	local prefix, current_state, suffix = raw_tag:match("^(%[R:[^|]+|)([^|%]]+)(.*)$")
	if not prefix then
		return raw_tag
	end
	local state_str = "unexplored"
	if #new_states > 0 then
		state_str = table.concat(new_states, ",")
	end
	return prefix .. state_str .. suffix
end

function M.edit_room_state()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cur_line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not cur_line then
		return
	end

	local raw_tag = cur_line:match("%[R:[^%]]+%]")
	if not raw_tag then
		vim.notify("lonelog: No room tag found at cursor", vim.log.levels.INFO)
		return
	end

	local current = M.parse_states(raw_tag)
	local current_set = {}
	for _, s in ipairs(current) do
		current_set[s] = true
	end

	local choices = {}
	for _, state in ipairs(ALL_STATES) do
		local prefix = current_set[state] and "[X]" or "[ ]"
		table.insert(choices, {
			label = prefix .. " " .. state,
			state = state,
		})
	end

	vim.ui.select(choices, {
		prompt = "Toggle room state:",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		local new_states = {}
		local found = false
		for _, s in ipairs(current) do
			if s == choice.state then
				found = true
			else
				table.insert(new_states, s)
			end
		end
		if not found then
			table.insert(new_states, choice.state)
		end
		local new_tag = M.build_tag(raw_tag, new_states)
		local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
		if line then
			local new_line = line:gsub("%[R:[^%]]+%]", new_tag, 1)
			vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
		end
	end)
end

return M
