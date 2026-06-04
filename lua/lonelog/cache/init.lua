local M = {}

-- Cache per buffer: maps bufnr -> { changedtick, data }
local cache = {}

local ENTITY_TYPES = {
  N = "N",
  L = "L",
  PC = "PC",
  THREAD = "THREAD",
  F = "F",
  INV = "INV",
  WEALTH = "WEALTH",
  R = "R",
}

local PROGRESS_TYPES = {
  E = true,
  CLOCK = true,
  TRACK = true,
  TIMER = true,
}

local CACHE_KEY_MAP = {
  N = "npcs",
  L = "locations",
  PC = "pcs",
  THREAD = "threads",
  F = "foes",
  INV = "inventory",
  WEALTH = "wealth",
  R = "rooms",
}

-- Normalize a clock/event/track/timer to the standard progress type string.
local function normalize_progress_type(raw_type)
  if raw_type == "CLOCK" then
    return "E"
  end
  return raw_type
end

-- Parse a d: buffer line like "d: 2d6+3[4, 2] = 10" into its components.
local function parse_dice_line(line)
	local notation, rolls_str, total_str = line:match("^d:%s*([^%[]+)%[([^%]]*)%]%s*=%s*(%d+)")
	if not notation then
		return nil
	end
	notation = vim.trim(notation)
	local total = tonumber(total_str)
	local rolls = {}
	for v in rolls_str:gmatch("(%d+)") do
		table.insert(rolls, tonumber(v))
	end
	return { notation = notation, rolls = rolls, total = total }
end

-- Aggregate roll data from history and buffer d: lines into the rolls output structure.
local function aggregate_rolls(bufnr)
	local dice_mod = require("lonelog.dice")
	local oracle_mod = require("lonelog.oracle")

	local dice_history = dice_mod.get_history(bufnr)
	local oracle_history = oracle_mod.get_history(bufnr)

	-- Parse d: lines from the buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local d_entries = {}
	for line_num, line in ipairs(lines) do
		local parsed = parse_dice_line(line)
		if parsed then
			d_entries[line_num] = parsed
		end
	end

	-- Build combined dice roll list: start with parsed d: line entries,
	-- then overlay with history entries (history wins on same line number).
	local dice_rolls = {}
	local seen_lines = {}
	for _, entry in ipairs(dice_history) do
		local line = entry.line
		table.insert(dice_rolls, {
			notation = entry.result.original,
			total = entry.result.total,
		})
		seen_lines[line] = true
	end
	for line_num, parsed in pairs(d_entries) do
		if not seen_lines[line_num] then
			table.insert(dice_rolls, {
				notation = parsed.notation,
				total = parsed.total,
			})
		end
	end

	-- Aggregate dice rolls by notation
	local by_notation = {}
	local fate_count = 0
	local success_counting_count = 0
	for _, roll in ipairs(dice_rolls) do
		local n = roll.notation
		if not by_notation[n] then
			by_notation[n] = {
				notation = n,
				count = 0,
				sum = 0,
				min = roll.total,
				max = roll.total,
			}
		end
		local entry = by_notation[n]
		entry.count = entry.count + 1
		entry.sum = entry.sum + roll.total
		if roll.total < entry.min then
			entry.min = roll.total
		end
		if roll.total > entry.max then
			entry.max = roll.total
		end

		-- Count fate dice and success-counting rolls
		if n:match("df") then
			fate_count = fate_count + 1
		end
		if n:match(">>") or n:match(">=") or n:match("<=") or n:match("vs") or n:match(">%d+$") then
			success_counting_count = success_counting_count + 1
		end
	end

	local by_type = {}
	for _, entry in pairs(by_notation) do
		entry.average = entry.count > 0 and math.floor((entry.sum / entry.count) * 10 + 0.5) / 10 or 0
		table.insert(by_type, entry)
	end
	table.sort(by_type, function(a, b)
		return a.notation < b.notation
	end)

	-- Aggregate oracle results by table and value, zero-filling expected values
	local ORACLE_EXPECTED = {
		fate = { "exceptional_yes", "yes", "yes_but", "maybe", "no_but", "no", "exceptional_no" },
		binary = { "yes", "no" },
	}
	local by_table = {}
	for _, entry in ipairs(oracle_history) do
		local tbl = entry.result.table or "unknown"
		local value = entry.result.value or "unknown"
		if not by_table[tbl] then
			by_table[tbl] = { table = tbl, results = {} }
		end
		by_table[tbl].results[value] = (by_table[tbl].results[value] or 0) + 1
	end

	-- Zero-fill expected values for known oracle tables
	for tbl_name, expected_vals in pairs(ORACLE_EXPECTED) do
		if not by_table[tbl_name] then
			by_table[tbl_name] = { table = tbl_name, results = {} }
		end
		for _, v in ipairs(expected_vals) do
			if by_table[tbl_name].results[v] == nil then
				by_table[tbl_name].results[v] = 0
			end
		end
	end

	local oracle_results = {}
	for _, tbl_entry in pairs(by_table) do
		table.insert(oracle_results, tbl_entry)
	end
	table.sort(oracle_results, function(a, b)
		return a.table < b.table
	end)

	return {
		by_type = by_type,
		total_rolls = #dice_rolls,
		fate_rolls = fate_count,
		success_counting = success_counting_count,
		oracle_results = oracle_results,
	}
end

-- Sort an array of entities by name (case-insensitive).
local function sort_by_name(arr)
  table.sort(arr, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  return arr
end

-- Aggregate entities from parsed tags.
-- Returns a table keyed by display key (npcs, locations, …).
local function aggregate_entities(all_tags)
  local by_type = {}

  for _, tag in ipairs(all_tags) do
    local t = tag.type
    if ENTITY_TYPES[t] then
      by_type[t] = by_type[t] or {}
      local name = tag.name
      local entry = by_type[t][name]
      if entry then
        table.insert(entry.lines, tag.line)
        entry.last_seen = tag.line
        entry.mention_count = entry.mention_count + 1
      else
        by_type[t][name] = {
          name = name,
          tags = tag.tags,
          lines = { tag.line },
          first_seen = tag.line,
          last_seen = tag.line,
          mention_count = 1,
        }
      end
    end
  end

  local result = {}
  for raw_type, cache_key in pairs(CACHE_KEY_MAP) do
    local gathered = by_type[raw_type]
    if gathered then
      local list = {}
      for _, entry in pairs(gathered) do
        table.insert(list, entry)
      end
      result[cache_key] = sort_by_name(list)
    else
      result[cache_key] = {}
    end
  end
  return result
end

-- Build progress array from parsed tags.
local function build_progress(all_tags)
  local progress = {}
  for _, tag in ipairs(all_tags) do
    local t = tag.type
    if PROGRESS_TYPES[t] then
      local current, max
      for _, s in ipairs(tag.tags) do
        local c, m = s:match("^(%d+)/(%d+)$")
        if c then
          current = tonumber(c)
          max = tonumber(m)
        else
          local c_only = tonumber(s:match("^(%d+)$"))
          if c_only then
            current = c_only
          end
        end
      end
      table.insert(progress, {
        type = normalize_progress_type(t),
        name = tag.name,
        current = current,
        max = max,
        line = tag.line,
      })
    end
  end
  return progress
end

--- Force a full re-parse for a given buffer.
---@param bufnr number|nil Buffer number (default: current)
---@return table Full cached data table
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local tags_mod = require("lonelog.parsers.tags")
  local scenes_mod = require("lonelog.parsers.scenes")
  local summary_mod = require("lonelog.commands.summary")

  local all_tags = tags_mod.parse_tags(bufnr)
  local all_scenes = scenes_mod.parse_scenes(bufnr)
  local all_sessions = summary_mod.parse_all_sessions(bufnr)

  local entities = aggregate_entities(all_tags)
  local progress = build_progress(all_tags)
  local rolls = aggregate_rolls(bufnr)

  local data = {
    tags = all_tags,
    npcs = entities.npcs,
    locations = entities.locations,
    pcs = entities.pcs,
    threads = entities.threads,
    foes = entities.foes,
    inventory = entities.inventory,
    wealth = entities.wealth,
    rooms = entities.rooms,
    progress = progress,
    scenes = all_scenes,
    sessions = all_sessions,
    rolls = rolls,
  }

  cache[bufnr] = {
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    data = data,
  }

  return data
end

--- Get cached data for a buffer, refreshing on changedtick mismatch.
---@param bufnr number|nil Buffer number (default: current)
---@return table Cached data table
function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local entry = cache[bufnr]
  local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  if entry and current_tick == entry.changedtick then
    return entry.data
  end
  return M.refresh(bufnr)
end

--- Invalidate the cache entry for a buffer.
---@param bufnr number|nil Buffer number (default: current)
function M.invalidate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cache[bufnr] = nil
end

return M
