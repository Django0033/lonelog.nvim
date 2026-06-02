local M = {}

-- Map tag type keys to human-readable names
local TAG_TYPES = {
	N = "NPC",
	L = "Location",
	E = "Event",
	PC = "PC",
	THREAD = "Thread",
	CLOCK = "Clock",
	TRACK = "Track",
	TIMER = "Timer",
	INV = "Inventory",
	WEALTH = "Wealth",
	R = "Room",
	F = "Foe",
}
M.TAG_TYPES = TAG_TYPES
local TAG_LABELS = {
	N = "NPCs",
	L = "Locations",
	E = "Events",
	PC = "Player Characters",
	THREAD = "Threads",
	CLOCK = "Clocks",
	TRACK = "Tracks",
	TIMER = "Timers",
	INV = "Inventory",
	WEALTH = "Wealth",
	R = "Rooms",
	F = "Foes",
}

-- Parse all Lonelog tags from a buffer
---@param bufnr number|nil Buffer number (default:current)
---@return table Array of parsed tags
function M.parse_tags(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local tags = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local i = 1
	while i <= #lines do
		local line = lines[i]

		-- Check for multi-line tag start: line has [TYPE: but no ]
		if line:match("^%[[%#]?%w+:") and not line:match("%]") then
			local ml_lines = { line }
			local j = i + 1
			local found_close = false
			while j <= #lines do
				table.insert(ml_lines, lines[j])
				if lines[j]:match("^%s*%]%s*$") then
					found_close = true
					break
				end
				j = j + 1
			end

			if found_close then
				local raw = table.concat(ml_lines, "\n")
				local parsed = M.parse_tag(raw, i)
				if parsed then
					table.insert(tags, parsed)
				end
				i = j
			end
		else
			-- Single-line tag matching
			for match in line:gmatch("%[[%#]?%w+:%s*[^%]]+%]") do
				local parsed = M.parse_tag(match, i)
				if parsed then
					table.insert(tags, parsed)
				end
			end
		end

		i = i + 1
	end
	return tags
end

-- Normalize multi-line tag format to single-line:
-- [N:Name\n  | content1\n  | content2\n] -> [N:Name|content1|content2]
function M._normalize_multiline(raw)
	local first = raw:match("^%[(.-)%s*\n")
	if not first then
		return raw
	end
	local pipes = {}
	for line in raw:gmatch("[^\n]+") do
		local content = line:match("^%s*|%s*(.-)%s*$")
		if content and content ~= "" then
			table.insert(pipes, content)
		end
	end
	if #pipes == 0 then
		return "[" .. first .. "]"
	end
	return "[" .. first .. "|" .. table.concat(pipes, "|") .. "]"
end

-- Parse a single tag string into an object
-- raw: the raw tag text like "[N:Jonah|friendly]" or multi-line content
-- line_num: line number where tag appears
function M.parse_tag(raw, line_num)
	-- Normalize multi-line to single-line format
	local is_multiline = raw:match("\n") ~= nil
	if is_multiline then
		raw = M._normalize_multiline(raw)
	end

	-- Check if it's a reference tag (starts with [#)
	local is_ref = raw:match("%[[%#]?") == "[#"
	-- Remove brackets
	local content = raw:gsub("^%[[%#]?", ""):gsub("%]$", "")
	-- Get tag type (first word before colon)
	local type_key = content:match("^(%w+)")
	if not type_key or not TAG_TYPES[type_key:upper()] then
		return nil
	end
	type_key = type_key:upper()
	-- Get everything after the type
	local rest = content:sub(#type_key + 2)
	-- Try to split name and tags by pipe
	local name, tags_str = rest:match("^([^%|]+)%|(.+)$")
	if not name then
		name = rest
		tags_str = ""
		-- Check for progress format like "Name 3/6"
		local prog = rest:match("^(.-)%s+(%d+/?%d*)$")
		if prog and prog ~= "" then
			name = prog
			tags_str = rest:match("%s+(%d+/?%d*)$")
		end
	end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	-- Parse tags into categories
	local tags, changes, adds, removes = {}, {}, {}, {}
	for t in tags_str:gmatch("[^%|]+") do
		local tag = t:gsub("^%s+", ""):gsub("%s+$", "")
		if tag:match("→") then
			table.insert(changes, tag) -- Change tracking
		elseif tag:match("^%+") then
			table.insert(adds, tag) -- Addition
		elseif tag:match("^%-") then
			table.insert(removes, tag) -- Removal
		else
			table.insert(tags, tag)
		end
	end
	return {
		type = type_key,
		type_label = TAG_TYPES[type_key],
		name = name,
		tags = tags,
		changes = changes,
		additions = adds,
		removals = removes,
		is_reference = is_ref,
		is_multiline = is_multiline or false,
		line = line_num,
		raw = raw,
	}
end

-- Format tag for display in picker
function M.format_tag_display(tag)
	local parts =
		{ "L" .. tag.line .. " | " .. (tag.is_reference and "#" or "") .. "[" .. tag.type .. "] " .. tag.name }
	if tag.is_multiline and #tag.tags > 0 then
		table.insert(parts, "\n" .. string.rep(" ", 8) .. "├─ " .. table.concat(tag.tags, "\n" .. string.rep(" ", 8) .. "├─ "))
	end
	if not tag.is_multiline and #tag.tags > 0 then
		table.insert(parts, " | " .. table.concat(tag.tags, ", "))
	end
	if #tag.changes > 0 then
		table.insert(parts, " | " .. table.concat(tag.changes, ", "))
	end
	if #tag.additions > 0 then
		table.insert(parts, " | " .. table.concat(tag.additions, ", "))
	end
	if #tag.removals > 0 then
		table.insert(parts, " | " .. table.concat(tag.removals, ", "))
	end
	return table.concat(parts, "")
end

-- Count tags by unique name
function M.tags_summary(tags)
	local s = {}
	local seen = {}
	for _, t in ipairs(tags) do
		s[t.type] = s[t.type] or { label = TAG_LABELS[t.type], count = 0 }
		local key = (t.name or ""):lower()
		seen[t.type] = seen[t.type] or {}
		if not seen[t.type][key] then
			seen[t.type][key] = true
			s[t.type].count = s[t.type].count + 1
		end
	end
	return s
end

-- Show picker for navigating tags
function M.show_tags_picker()
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		vim.notify("lonelog: No file name", vim.log.levels.WARN)
		return
	end
	local file_tags = M.parse_tags(bufnr)
	if #file_tags == 0 then
		vim.notify("lonelog: No tags found", vim.log.levels.INFO)
		return
	end
	table.sort(file_tags, function(a, b)
		return a.line < b.line
	end)

	-- Use native sidebar if Telescope is disabled
	if not require("lonelog.config").should_use_telescope() then
		M.show_tags_picker_native(file_tags)
		return
	end

	-- Open browser with tag groups
	M.show_tags_browser(file_tags)
end

local function open_tag_picker(filtered_tags, ui_pick)
	local items = {}
	for _, t in ipairs(filtered_tags) do
		table.insert(items, { tag = t, display = M.format_tag_display(t) })
	end
	ui_pick({
		title = "Lonelog Tags",
		items = items,
		format_item = function(item) return item.display end,
		on_select = function(c)
			if c then
				vim.api.nvim_win_set_cursor(0, { c.tag.line, 0 })
			end
		end,
	})
end

function M.show_tags_browser(all_tags)
	local summary = M.tags_summary(all_tags)
	local lines = { "  Lonelog Tags", "" }
	local group_info = {}
	local total_unique = 0
	for _, v in pairs(summary) do
		total_unique = total_unique + v.count
	end
	table.insert(lines, "    All Tags (" .. total_unique .. ")")
	table.insert(group_info, { label = lines[#lines], type_key = "all", tags = all_tags })
	for k, v in pairs(summary) do
		local label = "    " .. v.label .. " (" .. v.count .. ")"
		table.insert(lines, label)
		local filtered = vim.tbl_filter(function(t)
			return t.type == k
		end, all_tags)
		table.insert(group_info, { label = label, type_key = k, tags = filtered })
	end
	table.insert(lines, "")
	table.insert(lines, "  <CR> open picker    q close")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	vim.cmd("botright vnew")
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_win_set_width(0, 35)
	vim.api.nvim_buf_set_name(buf, "Lonelog Tags")

	local ui_pick = require("lonelog.ui").pick
	local function on_enter()
		local line = vim.fn.line(".")
		local idx = line - 2
		if idx < 0 or idx >= #group_info then
			return
		end
		vim.api.nvim_win_close(0, true)
		open_tag_picker(group_info[idx].tags, ui_pick)
	end

	vim.keymap.set("n", "<CR>", on_enter, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end, { buffer = buf, nowait = true, silent = true })
end

-- Native sidebar picker for tags
function M.show_tags_picker_native(all_tags)
	local summary = M.tags_summary(all_tags)
	local total_unique = 0
	for _, v in pairs(summary) do
		total_unique = total_unique + v.count
	end
	local type_items, key_by_type = {}, {}
	table.insert(type_items, "All Tags (" .. total_unique .. ")")
	key_by_type[1] = nil -- Index 1 is "All"
	local idx = 2
	for k, v in pairs(summary) do
		table.insert(type_items, v.label .. " (" .. v.count .. ")")
		key_by_type[idx] = k
		idx = idx + 1
	end

	local sidebar = require("lonelog.ui.sidebar")
	sidebar.open("Tags", type_items, {
		data = type_items,
		format_item = function(item)
			return item
		end,
		on_select = function(choice)
			-- Find which type was selected
			local type_idx = 0
			for i, item in ipairs(type_items) do
				if item == choice then
					type_idx = i
					break
				end
			end
			local type_key = key_by_type[type_idx]
			local filtered = type_key and vim.tbl_filter(function(t)
				return t.type == type_key
			end, all_tags) or all_tags
			if #filtered == 0 then
				return
			end
			local display_items = {}
			for _, t in ipairs(filtered) do
				table.insert(display_items, M.format_tag_display(t))
			end
			sidebar.open("Tags - " .. choice, display_items, {
				data = filtered,
				on_select = function(tag)
					vim.api.nvim_win_set_cursor(0, { tag.line, 0 })
				end,
			})
		end,
	})
end

return M
