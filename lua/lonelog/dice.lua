local M = {}

-- Roll history: keyed by bufnr -> { result, line, timestamp }[]
local roll_history = {}

-- Seed random number generator with current time
function M.setup()
	math.randomseed(os.time())
end

-- Roll a single die with given number of sides
local function roll_die(sides)
	return math.random(1, sides)
end

-- Parse dice notation string into components
-- Example: "2d6+3" -> {count=2, sides=6, modifier=3}
local function parse_notation(notation)
	-- Initialize with all possible options set to 0 or false
	local p = {
		original = notation,
		count = 0,
		sides = 0,
		modifier = 0,
		keep_highest = 0,
		keep_lowest = 0,
		exploding = false,
		target = 0,
		target_mode = nil,
		operator = nil,
		is_fate = false,
	}
	notation = notation:gsub("%s+", ""):upper()

	-- Check for exploding dice (e.g., "4d6!")
	if notation:match("!+") then
		p.exploding = true
		notation = notation:gsub("!+", "")
	end

	-- Check for success counting mode (e.g., "6d6>>4")
	local mt = notation:match(">>%d+")
	if mt then
		p.target = tonumber(mt:sub(3))
		p.target_mode = "successes"
		notation = notation:gsub(">>%d+", "")
	end

	-- Check for sum vs target operators (order matters: multi-char before single-char)
	if not p.target_mode then
		mt = notation:match(">=%d+")
		if mt then
			p.operator = ">="
			p.target = tonumber(mt:sub(3))
			p.target_mode = "sum"
			notation = notation:gsub(">=%d+", "")
		end
	end

	if not p.target_mode then
		mt = notation:match("<=%d+")
		if mt then
			p.operator = "<="
			p.target = tonumber(mt:sub(3))
			p.target_mode = "sum"
			notation = notation:gsub("<=%d+", "")
		end
	end

	if not p.target_mode then
		mt = notation:match(">%d+")
		if mt then
			p.operator = ">"
			p.target = tonumber(mt:sub(2))
			p.target_mode = "sum"
			notation = notation:gsub(">%d+", "")
		end
	end

	if not p.target_mode then
		-- 'vs' check after whitespace stripped, so no space between vs and number
		mt = notation:match("VS%d+")
		if mt then
			p.operator = "vs"
			p.target = tonumber(mt:match("%d+"))
			p.target_mode = "sum"
			notation = notation:gsub("vs%d+", "")
		end
	end

	-- Extract dice count and sides (e.g., "2d6")
	local c, s = notation:match("^(%d+)[dD](%d+)")
	if c and s then
		p.count = tonumber(c)
		p.sides = tonumber(s)
	else
		-- Check for Fate dice (e.g., "4df")
		local fc = notation:match("^(%d+)[dD][Ff]")
		if fc then
			p.count = tonumber(fc)
			p.is_fate = true
		else
			return nil
		end
	end

	-- Extract modifier (e.g., "+3" or "-2")
	local mod = notation:match("[+-]%d+$")
	if mod then
		p.modifier = tonumber(mod)
	end

	return p
end

-- Roll a single die, handling exploding dice recursively
local function roll_single(sides, exploding, exploded)
	exploded = exploded or {}
	local roll = roll_die(sides)
	table.insert(exploded, roll)
	-- If exploding and rolled max, roll again (max 100 rolls to prevent infinite loops)
	if exploding and roll == sides and #exploded < 100 then
		return roll_single(sides, exploding, exploded)
	end
	return exploded
end

local function calc_total(kept, modifier, target, target_mode)
	local total = 0
	if target > 0 then
		if target_mode == "sum" then
			for _, r in ipairs(kept) do total = total + r end
			total = total + modifier
		else
			for _, r in ipairs(kept) do
				if r >= target then total = total + 1 end
			end
		end
	else
		for _, r in ipairs(kept) do total = total + r end
		total = total + modifier
	end
	return total
end

local function build_display(parsed, kept, total)
	local parts, dice_str = {}, parsed.count .. "d" .. parsed.sides
	if parsed.exploding then dice_str = dice_str .. "!" end
	if parsed.keep_highest > 0 then
		dice_str = dice_str .. "kh" .. parsed.keep_highest
	elseif parsed.keep_lowest > 0 then
		dice_str = dice_str .. "kl" .. parsed.keep_lowest
	end
	if parsed.target > 0 then
		if parsed.modifier ~= 0 then
			local s = parsed.modifier > 0 and "+" or ""
			dice_str = dice_str .. s .. parsed.modifier
		end
		dice_str = dice_str .. (parsed.target_mode == "successes" and ">>" or parsed.operator) .. parsed.target
	elseif parsed.modifier ~= 0 then
		local s = parsed.modifier > 0 and "+" or ""
		dice_str = dice_str .. s .. parsed.modifier
	end
	table.insert(parts, dice_str)
	table.insert(parts, "[" .. table.concat(kept, ", ") .. "]")

	if parsed.target > 0 then
		if parsed.target_mode == "successes" then
			table.insert(parts, " successes")
		else
			local sum = 0
			for _, r in ipairs(kept) do sum = sum + r end
			sum = sum + parsed.modifier
			local op = parsed.operator or ">"
			local ok = op == "<=" and sum <= parsed.target
				or (op == ">" and sum > parsed.target)
				or (sum >= parsed.target)
			table.insert(parts, string.format(" = %d %s %d -> %s", sum, op, parsed.target, ok and "Success" or "Fail"))
			total = sum
		end
	elseif parsed.modifier ~= 0 then
		table.insert(parts, " = " .. tostring(total))
	else
		table.insert(parts, " = " .. tostring(total))
	end
	return total, table.concat(parts, "")
end

-- Main dice rolling function
-- Parses notation, rolls dice, and returns result object
function M.roll(notation)
	if type(notation) ~= "string" then
		return nil, "Notation must be a string"
	end
	local parsed = parse_notation(notation)
	if not parsed then
		return nil, "Invalid dice notation: " .. notation
	end
	local cfg = require("lonelog.config").get()
	if parsed.count > cfg.dice.max_dice then
		return nil, "Too many dice (max: " .. cfg.dice.max_dice .. ")"
	end
	if not parsed.is_fate and parsed.sides > cfg.dice.max_sides then
		return nil, "Too many sides (max: " .. cfg.dice.max_sides .. ")"
	end

	-- Handle Fate dice (4df)
	if parsed.is_fate then
		local symbols = { "-", "-", "0", "0", "+", "+" }
		local fate_rolls = {}
		local fate_total = 0
		for i = 1, parsed.count do
			local r = symbols[math.random(1, 6)]
			table.insert(fate_rolls, r)
			if r == "+" then
				fate_total = fate_total + 1
			elseif r == "-" then
				fate_total = fate_total - 1
			end
		end
		fate_total = fate_total + parsed.modifier
		local total_str = fate_total > 0 and "+" .. fate_total or tostring(fate_total)
		local dice_str = parsed.count .. "df"
		if parsed.modifier ~= 0 then
			local s = parsed.modifier > 0 and "+" or ""
			dice_str = dice_str .. s .. parsed.modifier
		end
		return {
			original = notation,
			count = parsed.count,
			sides = 0,
			modifier = parsed.modifier,
			is_fate = true,
			rolls = fate_rolls,
			total = fate_total,
			display = dice_str .. "[" .. table.concat(fate_rolls, ", ") .. "] = " .. total_str,
		}
	end

	-- Roll all dice (each die may produce multiple rolls if exploding)
	local all_rolls = {}
	for i = 1, parsed.count do
		for _, r in ipairs(roll_single(parsed.sides, parsed.exploding, {})) do
			table.insert(all_rolls, r)
		end
	end

	-- Apply keep highest/lowest if specified
	local kept = all_rolls
	if parsed.keep_highest > 0 then
		table.sort(all_rolls, function(a, b) return a > b end)
		kept = vim.list_slice(all_rolls, 1, parsed.keep_highest)
	elseif parsed.keep_lowest > 0 then
		table.sort(all_rolls, function(a, b) return a < b end)
		kept = vim.list_slice(all_rolls, 1, parsed.keep_lowest)
	end

	local total = calc_total(kept, parsed.modifier, parsed.target, parsed.target_mode)
	local display
	total, display = build_display(parsed, kept, total)
	return {
		original = notation,
		count = parsed.count,
		sides = parsed.sides,
		rolls = kept,
		all_rolls = all_rolls,
		modifier = parsed.modifier,
		target = parsed.target,
		exploding = parsed.exploding,
		operator = parsed.operator,
		total = total,
		display = display,
	}
end

-- History accessors

--- Get roll history for a buffer.
---@param bufnr? number Buffer number (defaults to 0 for current buffer)
---@return table[] Array of { result, line, bufnr } entries
function M.get_history(bufnr)
	bufnr = bufnr or 0
	return roll_history[bufnr] or {}
end

--- Clear roll history for a buffer.
---@param bufnr? number Buffer number (defaults to 0 for current buffer)
function M.clear_history(bufnr)
	bufnr = bufnr or 0
	roll_history[bufnr] = {}
end

--- Add a roll result to history.
---@param bufnr number Buffer number
---@param result table Roll result from M.roll()
---@param line number Line number where roll was triggered
function M.add_to_history(bufnr, result, line)
	if not roll_history[bufnr] then
		roll_history[bufnr] = {}
	end
	table.insert(roll_history[bufnr], {
		result = result,
		line = line,
		bufnr = bufnr,
	})
end

return M
