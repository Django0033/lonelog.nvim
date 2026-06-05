local M = {}

-- Oracle roll history: keyed by bufnr -> { result, line, timestamp }[]
local oracle_history = {}

-- Chaos factor modifiers for Mythic oracle (indexed by chaos 1-9)
local CHAOS_MODIFIERS = { [1] = -5, [2] = -4, [3] = -2, [4] = -1, [5] = 0, [6] = 1, [7] = 2, [8] = 4, [9] = 5 }
local MYTHIC_EXCEPTIONAL = 4
local MYTHIC_NO = 10
local MYTHIC_YES = 17
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

-- Initialize custom oracle tables from user config.
-- Accepts array format (equal weight) or dict format (explicit weights).
---@param custom_tables table<string, table>
function M.init(custom_tables)
	if not custom_tables then
		return
	end
	for name, entries in pairs(custom_tables) do
		local normalized = {}
		-- Detect array vs dict: consecutive numeric keys with string values → array
		if #entries > 0 then
			-- Array format: {"A", "B", "C"} → equal weight
			for _, v in ipairs(entries) do
				normalized[#normalized + 1] = {
					value = v,
					display = v,
					weight = 1,
				}
			end
		else
			-- Dict format: {A = 5, B = 3} → use weights as-is
			for k, v in pairs(entries) do
				normalized[#normalized + 1] = {
					value = k,
					display = k,
					weight = v,
				}
			end
		end
		-- Override or add to tables (lowercase key to match M.roll() lookup)
		tables[name:lower()] = {
			name = name:sub(1, 1):upper() .. name:sub(2) .. " Oracle",
			entries = normalized,
		}
	end
end

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
		M.save_chaos()
		return true
	end
	return false
end

-- Get path to chaos factor file
local function get_chaos_file_path()
	local cfg = require("lonelog.config").get().oracle
	local data_dir = vim.fn.stdpath("data") .. "/lonelog"
	return data_dir .. "/" .. cfg.chaos_file
end

-- Load chaos factor from file
function M.load_chaos()
	local cfg = require("lonelog.config").get().oracle
	if not cfg.persist_chaos then
		return
	end

	local filepath = get_chaos_file_path()
	local fd = io.open(filepath, "r")
	if fd then
		local content = fd:read("*all")
		fd:close()
		local chaos = tonumber(content:match("%d"))
		if chaos and chaos >= 1 and chaos <= 9 then
			chaos_factor = chaos
		end
	end
end

-- Save chaos factor to file
function M.save_chaos()
	local cfg = require("lonelog.config").get().oracle
	if not cfg.persist_chaos then
		return
	end

	local filepath = get_chaos_file_path()
	vim.fn.mkdir(vim.fn.stdpath("data") .. "/lonelog", "p")
	local fd = io.open(filepath, "w")
	if fd then
		fd:write(tostring(chaos_factor))
		fd:close()
	end
end

local function build_chaos_content(chaos)
	return {
		"",
		"  Chaos Factor: " .. chaos,
		"  Range: 1-9",
		"",
		"  [-] Decrease [+] Increase",
		"  [Enter] Confirm [q] Close",
	}
end

function M.show_chaos_ui()
	local chaos = M.get_chaos()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, build_chaos_content(chaos))

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = 30,
		height = 8,
		row = math.floor((vim.o.lines - 8) / 2),
		col = math.floor((vim.o.columns - 30) / 2),
		style = "minimal",
		border = "rounded",
		title = " Mythic Chaos Factor ",
	})

	-- Helper to update buffer and close window
	local function close_win()
		vim.api.nvim_win_close(win, true)
	end

	local function update_buffer()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, build_chaos_content(chaos))
	end

	-- Keybindings
	vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "+", function()
		if chaos < 9 then
			chaos = chaos + 1
			update_buffer()
		end
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "-", function()
		if chaos > 1 then
			chaos = chaos - 1
			update_buffer()
		end
	end, { buffer = buf, nowait = true, silent = true })

	local function confirm_and_close()
		M.set_chaos(chaos)
		close_win()
	end

	vim.keymap.set("n", "<CR>", confirm_and_close, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<Enter>", confirm_and_close, { buffer = buf, nowait = true, silent = true })
end

-- Roll Mythic oracle using 2d10 + chaos modifier
function M.mythic_roll(chaos)
	local chaos_mod = CHAOS_MODIFIERS[chaos] or 0
	local d10_1, d10_2 = math.random(1, 10), math.random(1, 10)
	local final = d10_1 + d10_2 + chaos_mod
	local result_val, display_val
	if final <= MYTHIC_EXCEPTIONAL then
		result_val, display_val = "exceptional_no", "Exceptional No"
	elseif final <= MYTHIC_NO then
		result_val, display_val = "no", "No"
	elseif final <= MYTHIC_YES then
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

-- List all available oracle tables (sorted for deterministic order)
function M.list_tables()
	local r = {}
	for k in pairs(tables) do
		table.insert(r, k:sub(1, 1):upper() .. k:sub(2))
	end
	table.sort(r)
	return r
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

-- History accessors

--- Get oracle roll history for a buffer.
---@param bufnr? number Buffer number (defaults to 0 for current buffer)
---@return table[] Array of { result, line, bufnr } entries
function M.get_history(bufnr)
	bufnr = bufnr or 0
	return oracle_history[bufnr] or {}
end

--- Clear oracle roll history for a buffer.
---@param bufnr? number Buffer number (defaults to 0 for current buffer)
function M.clear_history(bufnr)
	bufnr = bufnr or 0
	oracle_history[bufnr] = {}
end

--- Add an oracle result to history.
---@param bufnr number Buffer number
---@param result table Result from M.roll()
---@param line number Line number where roll was triggered
function M.add_to_history(bufnr, result, line)
	if not oracle_history[bufnr] then
		oracle_history[bufnr] = {}
	end
	table.insert(oracle_history[bufnr], {
		result = result,
		line = line,
		bufnr = bufnr,
	})
end

return M
