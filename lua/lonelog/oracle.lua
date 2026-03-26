local M = {}

-- Chaos factor modifiers for Mythic oracle (indexed by chaos 1-9)
local CHAOS_MODIFIERS = { [1] = -5, [2] = -4, [3] = -2, [4] = -1, [5] = 0, [6] = 1, [7] = 2, [8] = 4, [9] = 5 }
local chaos_factor = 5

-- Oracle tables with weighted entries
local tables = {
	fate = {
		name = "Fate Oracle",
		entries = {
			{ value = "exceptional_yes", display = "Exceptional Yes", weight = 8 },
			{ value = "yes", display = "Yes", weight = 23 },
			{ value = "yes_but", display = "Yes, but...", weight = 15 },
			{ value = "maybe", display = "Maybe", weight = 28 },
			{ value = "no_but", display = "No, but...", weight = 15 },
			{ value = "no", display = "No", weight = 8 },
			{ value = "exceptional_no", display = "Exceptional No", weight = 3 },
		},
	},
	binary = {
		name = "Binary Oracle",
		entries = {
			{ value = "yes", display = "Yes", weight = 50 },
			{ value = "no", display = "No", weight = 50 },
		},
	},
	mythic = { name = "Mythic Oracle", entries = {} },
}

-- Select random entry from table using weighted probability
local function weighted_random(entries)
	local total = 0
	for _, e in ipairs(entries) do
		total = total + e.weight
	end
	local roll = math.random(1, total)
	local current = 0
	for _, entry in ipairs(entries) do
		current = current + entry.weight
		if roll <= current then
			return entry
		end
	end
	return entries[#entries]
end

-- Get current chaos factor (for Mythic oracle)
function M.get_chaos()
	return chaos_factor
end

-- Set chaos factor (must be 1-9)
function M.set_chaos(value)
	if value and value >= 1 and value <= 9 then
		chaos_factor = value
		return true
	end
	return false
end

-- Roll Mythic oracle using 2d10 + chaos modifier
function M.mythic_roll(chaos)
	local chaos_mod = CHAOS_MODIFIERS[chaos] or 0
	local d10_1, d10_2 = math.random(1, 10), math.random(1, 10)
	local final = d10_1 + d10_2 + chaos_mod
	local result_val, display_val
	if final <= 4 then
		result_val, display_val = "exceptional_no", "Exceptional No"
	elseif final <= 10 then
		result_val, display_val = "no", "No"
	elseif final <= 17 then
		result_val, display_val = "yes", "Yes"
	else
		result_val, display_val = "exceptional_yes", "Exceptional Yes"
	end
	return {
		table = "mythic",
		table_name = "Mythic",
		value = result_val,
		display = display_val,
		chaos = chaos,
		chaos_modifier = chaos_mod,
		d10 = { d10_1, d10_2 },
		dice_total = d10_1 + d10_2,
		final = final,
	}
end

-- Roll oracle from specified table (or default)
-- table_name: "fate", "binary", or "mythic"
function M.roll(table_name)
	local cfg = require("lonelog.config").get()
	table_name = table_name and table_name:lower() or cfg.oracle.default_table
	if table_name == "mythic" then
		return M.mythic_roll(chaos_factor)
	end
	if not tables[table_name] then
		return nil, "Unknown oracle table: " .. table_name
	end
	local result = weighted_random(tables[table_name].entries)
	return {
		table = table_name,
		table_name = tables[table_name].name,
		value = result.value,
		display = result.display,
		description = "",
	}
end

-- List all available oracle tables
function M.list_tables()
	local r = {}
	for k in pairs(tables) do
		table.insert(r, k:sub(1, 1):upper() .. k:sub(2))
	end
	return r
end

-- Get oracle table definition by name
function M.get_table(name)
	return tables[name] and vim.deepcopy(tables[name]) or nil
end

-- Format oracle result for display
function M.format_result(result)
	if not result then
		return "No result"
	end
	if result.table == "mythic" then
		local cs = result.chaos_modifier >= 0 and ("+" .. result.chaos_modifier) or tostring(result.chaos_modifier)
		return string.format(
			"[%s] (2d10: %d + chaos(%s) = %d) %s",
			result.table_name,
			result.dice_total,
			cs,
			result.final,
			result.display
		)
	end
	return string.format("[%s] %s", result.table_name, result.display)
end

return M
