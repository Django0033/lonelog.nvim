local M = {}

--- Check if a stats field indicates death.
--- A combatant is dead if the field starts with "dead" (case-insensitive)
--- or matches `HP N` where N ≤ 0.
---@param field string
---@return boolean
function M.is_dead(field)
	local lower = field:lower()
	if lower:match("^dead") then
		return true
	end
	local n = lower:match("^hp (%-?%d+)")
	if n then
		return tonumber(n) <= 0
	end
	return false
end

--- Parse a single combatant tag from a line.
---@param line string
---@return table|nil
local function parse_combatant(line)
	local pc_name, pc_field = line:match("%[PC:([^|]+)%|([^|%]]+)")
	if pc_name then
		return {
			type = "PC",
			name = pc_name,
			stats = { pc_field },
			line = 0,
		}
	end
	local foe_name, foe_field = line:match("%[F:([^|]+)%|([^|%]]+)")
	if foe_name then
		return {
			type = "foe",
			name = foe_name,
			stats = { foe_field },
			line = 0,
		}
	end
	return nil
end

--- Update an existing combatant's stats or insert a new one.
---@param combatants table[]
---@param tag_line string
---@param line_num number
local function update_combatant(combatants, tag_line, line_num)
	local parsed = parse_combatant(tag_line)
	if not parsed then
		return
	end
	for _, c in ipairs(combatants) do
		if c.name == parsed.name and c.type == parsed.type then
			c.stats = parsed.stats
			c.line = line_num
			c.is_dead = M.is_dead(c.stats[1] or "")
			return
		end
	end
	parsed.line = line_num
	parsed.is_dead = M.is_dead(parsed.stats[1] or "")
	table.insert(combatants, parsed)
end

--- Parse a roster line like "R1 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]"
--- and add new combatants (excluding dead entries).
---@param line string
---@param combatants table[]
---@param line_num number
local function parse_roster_line(line, combatants, line_num)
	local roster = {}
	for tag in line:gmatch("%[([^%]]+)%]") do
		local t, name, field = tag:match("^(%w+):([^|]+)%|(.+)$")
		if t then
			table.insert(roster, { type = t, name = name, field = field })
		end
	end
	for _, entry in ipairs(roster) do
		if not M.is_dead(entry.field) then
			local mapped_type = entry.type == "PC" and "PC" or "foe"
			local found = false
			for _, c in ipairs(combatants) do
				if c.name == entry.name and c.type == mapped_type then
					found = true
					break
				end
			end
			if not found then
				local stats = { entry.field }
				table.insert(combatants, {
					type = mapped_type,
					name = entry.name,
					stats = stats,
					is_dead = M.is_dead(stats[1] or ""),
					line = line_num,
				})
			end
		end
	end
end

--- Classify a non-delimiter, non-round line within a combat block.
---@param line string
---@return string type
local function classify_action(line)
	if line:match("^@") then
		return "narrative"
	end
	if line:match("^d:") then
		return "dice"
	end
	if line:match("^%*") then
		return "note"
	end
	if line:match("%[PC:[^%]]+%]") or line:match("%[F:[^%]]+%]") then
		return "tag"
	end
	return "action"
end

--- Parse a single combat block from start_line to end_line (inclusive).
---@param lines string[]
---@param start_line number
---@param end_line number|nil
---@return table
local function parse_combat_block(lines, start_line, end_line)
	local block = {
		start_line = start_line,
		end_line = end_line,
		current_round = 0,
		is_closed = end_line ~= nil,
		combatants = {},
		rounds = {},
		actions = {},
	}

	for i = start_line, end_line or #lines do
		local line = lines[i]
		if not line then
			break
		end

		-- Skip delimiter lines (block start/end)
		if line:match("^%[COMBAT%]$") or line:match("^%[/COMBAT%]$") then
			goto continue
		end

		-- Roster line (includes round marker)
		if line:match("^R%d+ Roster:") then
			parse_roster_line(line, block.combatants, i)
			if #block.rounds > 0 then
				table.insert(block.rounds[#block.rounds].roster_lines, i)
			end
			goto continue
		end

		-- Round marker
		local round_num = line:match("^R(%d+)")
		if round_num then
			local n = tonumber(round_num)
			if n then
				block.current_round = math.max(block.current_round, n)
				table.insert(block.rounds, { number = n, line = i, roster_lines = {} })
			end
			goto continue
		end

		-- Tag / combatant update
		local tag_match = line:match("%[PC:[^%]]+%]") or line:match("%[F:[^%]]+%]")
		if tag_match then
			update_combatant(block.combatants, tag_match, i)
		end

		-- Action classification (for all non-delimiter, non-round, non-blank lines)
		if line ~= "" then
			table.insert(block.actions, {
				type = classify_action(line),
				content = line,
				line = i,
			})
		end

		::continue::
	end

	return block
end

--- Parse combat [COMBAT]..[/COMBAT] blocks from a buffer.
---@param bufnr? number Buffer number (default: current buffer)
---@return table[] Array of CombatBlock objects
function M.parse_combat_blocks(bufnr)
	local lines
	if type(bufnr) == "table" then
		-- Allow passing lines directly (for test compatibility)
		lines = bufnr
	else
		bufnr = bufnr or vim.api.nvim_get_current_buf()
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
			table.insert(blocks, parse_combat_block(lines, start, end_line))
		end
		i = i + 1
	end

	return blocks
end

return M
