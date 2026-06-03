-- NOTE: This file is currently only used by test files (test_combat_parser.lua).
-- It is NOT required by any production source code in `/lua/`.
-- The addon `lonelog.addons.combat.round` provides similar functionality
-- with its own copy of the `is_dead` helper.
local M = {}

local function is_dead(field)
	local lower = field:lower()
	if lower:match("^dead") then
		return true
	end
	local n = lower:match("^hp (%-?%d+)")
	return n and tonumber(n) <= 0
end

local function parse_combatant(line)
	local pc_name, pc_field = line:match("%[PC:([^|]+)%|([^|%]]+)")
	if pc_name then
		return { type = "PC", name = pc_name, stats = { pc_field }, line = 0 }
	end
	local foe_name, foe_field = line:match("%[F:([^|]+)%|([^|%]]+)")
	if foe_name then
		return { type = "foe", name = foe_name, stats = { foe_field }, line = 0 }
	end
	return nil
end

local function update_combatant(combatants, tag_line, line_num)
	local parsed = parse_combatant(tag_line)
	if not parsed then
		return
	end
	for _, c in ipairs(combatants) do
		if c.name == parsed.name and c.type == parsed.type then
			c.stats = parsed.stats
			c.line = line_num
			return
		end
	end
	parsed.line = line_num
	table.insert(combatants, parsed)
end

local function parse_roster_line(line, combatants, line_num)
	local roster = {}
	for tag in line:gmatch("%[([^%]]+)%]") do
		local t, name, field = tag:match("^(%w+):([^|]+)%|(.+)$")
		if t then
			table.insert(roster, { type = t, name = name, field = field })
		end
	end
	for _, entry in ipairs(roster) do
		if not is_dead(entry.field) then
			local found = false
			for _, c in ipairs(combatants) do
				if c.name == entry.name and c.type == entry.type then
					found = true
					break
				end
			end
			if not found then
				local stats = {}
				if entry.field then
					table.insert(stats, entry.field)
				end
				table.insert(combatants, {
					type = entry.type == "PC" and "PC" or "foe",
					name = entry.name,
					stats = stats,
					line = line_num,
				})
			end
		end
	end
end

function M.parse_combat_block(lines, start_line, end_line)
	local block = {
		start_line = start_line,
		end_line = end_line,
		current_round = 0,
		is_closed = end_line ~= nil,
		combatants = {},
		rounds = {},
	}

	for i = start_line, end_line or #lines do
		local line = lines[i]
		if not line then
			break
		end

		if line:match("^R%d+ Roster:") then
			parse_roster_line(line, block.combatants, i)
			if #block.rounds > 0 then
				table.insert(block.rounds[#block.rounds].roster_lines, i)
			end
			goto continue
		end

		local round_num = line:match("^R(%d+)")
		if round_num then
			local n = tonumber(round_num)
			if n then
				block.current_round = math.max(block.current_round, n)
				table.insert(block.rounds, { number = n, line = i, roster_lines = {} })
			end
			goto continue
		end

		local tag_match = line:match("%[PC:[^%]]+%]") or line:match("%[F:[^%]]+%]")
		if tag_match then
			update_combatant(block.combatants, tag_match, i)
		end

		::continue::
	end

	return block
end

function M.parse_combat_blocks(input)
	local lines
	if type(input) == "table" then
		lines = input
	else
		local bufnr = input or vim.api.nvim_get_current_buf()
		lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	end
	local blocks = {}
	local i = 1

	while i <= #lines do
		if lines[i]:match("^%[COMBAT%]$") then
			local start = i
			local end_line = nil
			i = i + 1
			while i <= #lines do
				if lines[i]:match("^%[/COMBAT%]$") then
					end_line = i
					break
				end
				i = i + 1
			end
			table.insert(blocks, M.parse_combat_block(lines, start, end_line))
		end
		i = i + 1
	end

	return blocks
end

return M
