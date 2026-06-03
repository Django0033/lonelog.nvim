local M = {}

-- Map scene type keys to labels
local SCENE_TYPES = {
	main = { label = "Main", plural = "Main Scenes" },
	flashback = { label = "Flashback", plural = "Flashbacks" },
	sub = { label = "Sub-scene", plural = "Sub-scenes" },
	thread = { label = "Thread", plural = "Thread Scenes" },
}

-- Parse all scenes from a buffer
function M.parse_scenes(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local scenes = {}
	for line_num, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
		local parsed = M.parse_scene(line, line_num)
		if parsed then
			table.insert(scenes, parsed)
		end
	end
	return scenes
end

-- Parse a single scene line into an object
-- Handles: S1, S5a, S7.1, T1-S1, T1+T2-S5
function M.parse_scene(line, line_num)
	line = line:match("^%s*(.-)%s*$") -- Trim whitespace
	local scene_id, rest
	-- Match various scene ID patterns
	if line:match("T[0-9]+%+[0-9]*T?[0-9]+%-S") then
		scene_id = line:match("T[0-9]+%+[0-9]*T?[0-9]+%-S[0-9]*[a-z]?")
	elseif line:match("T[0-9]+%-S") then
		scene_id = line:match("T[0-9]+%-S[0-9]*[a-z]?")
	elseif line:match("S[0-9]+%.[0-9]+") then
		scene_id = line:match("S[0-9]+%.[0-9]+")
	elseif line:match("S[0-9]+[a-z]") then
		scene_id = line:match("S[0-9]+[a-z]")
	elseif line:match("S[0-9]+") then
		scene_id = line:match("S[0-9]+")
	else
		return nil
	end
	local start = string.find(line, scene_id, 1, true)
	rest = line:sub(start + #scene_id)
	-- Classify and create appropriate sort key
	if scene_id:match("^T") then
		local t1, s
		if scene_id:match("T[%d%a]+%+") then
			t1, s = scene_id:match("^T[%d%a]*%+?([^%+%-]+)%-S([^%[%s]+)")
		else
			t1, s = scene_id:match("^T([^%-]+)%-S([^%[%s]+)")
		end
		if not t1 or not s then
			return nil
		end
		local sort_t = tonumber(t1) or 0
		return {
			type = "thread",
			type_label = SCENE_TYPES.thread.label,
			scene_id = scene_id,
			context = rest:match("%*(.-)%*"),
			location = rest:match("%[L:([^%]]+)"),
			line = line_num,
			raw = line,
			sort_key = string.format("%06d.%06d", sort_t + 1000, tonumber(s) or 0),
		}
	elseif scene_id:match("^S%d+[a-z]") then
		local num, let = scene_id:match("^S(%d+)([a-z])")
		return {
			type = "flashback",
			type_label = SCENE_TYPES.flashback.label,
			scene_id = scene_id,
			context = rest:match("%*(.-)%*"),
			location = rest:match("%[L:([^%]]+)"),
			line = line_num,
			raw = line,
			sort_key = string.format("%06d.%02d", tonumber(num), string.byte(let) - 96),
		}
	elseif scene_id:match("^S%d+%.") then
		local num, sub = scene_id:match("^S(%d+)%.(%d+)")
		return {
			type = "sub",
			type_label = SCENE_TYPES.sub.label,
			scene_id = scene_id,
			context = rest:match("%*(.-)%*"),
			location = rest:match("%[L:([^%]]+)"),
			line = line_num,
			raw = line,
			sort_key = string.format("%06d.%06d", tonumber(num), tonumber(sub)),
		}
	else
		return {
			type = "main",
			type_label = SCENE_TYPES.main.label,
			scene_id = scene_id,
			context = rest:match("%*(.-)%*"),
			location = rest:match("%[L:([^%]]+)"),
			line = line_num,
			raw = line,
			sort_key = string.format("%06d.000", tonumber(scene_id:match("%d+"))),
		}
	end
end

-- Format scene for display in picker
function M.format_scene_display(scene)
	local parts = { "[" .. scene.type_label .. "] " .. scene.scene_id }
	if scene.context then
		table.insert(parts, " * " .. scene.context .. " *")
	elseif scene.location then
		table.insert(parts, " * " .. scene.location .. " *")
	end
	return table.concat(parts, "")
end

-- Count scenes by type
function M.scenes_summary(scenes)
	local s = {}
	for _, sc in ipairs(scenes) do
		s[sc.type] = s[sc.type] or { label = SCENE_TYPES[sc.type].plural, count = 0 }
		s[sc.type].count = s[sc.type].count + 1
	end
	return s
end

-- Sort scenes by sort_key
function M.sort_scenes(scenes)
	table.sort(scenes, function(a, b)
		return a.sort_key < b.sort_key
	end)
	return scenes
end

-- Extract scene ID from a line (handles markdown headers and bare IDs)
local function extract_scene_id(line)
	local trimmed = line:match("^%s*(.-)%s*$") or ""
	local id = trimmed:match("^###%s+(S[%d%.a-z]+)")
		or trimmed:match("^###%s+(T[%d%+]+%-S[%d%.a-z]+)")
	if id then return id end
	if trimmed:match("T[0-9]+%+[0-9]*T?[0-9]+%-S") then
		return trimmed:match("T[0-9]+%+[0-9]*T?[0-9]+%-S[0-9]*[a-z]?")
	elseif trimmed:match("T[0-9]+%-S") then
		return trimmed:match("T[0-9]+%-S[0-9]*[a-z]?")
	elseif trimmed:match("S[0-9]+%.[0-9]+") then
		return trimmed:match("S[0-9]+%.[0-9]+")
	elseif trimmed:match("S[0-9]+[a-z]") then
		return trimmed:match("S[0-9]+[a-z]")
	elseif trimmed:match("S[0-9]+") then
		return trimmed:match("S[0-9]+")
	end
	return nil
end

-- Compute the next scene ID from a given scene ID
function M.next_scene_id(scene_id)
	if scene_id:match("^T") then
		local prefix, num = scene_id:match("^(.-S)(%d+)$")
		if prefix and num then
			return prefix .. tostring(tonumber(num) + 1)
		end
	elseif scene_id:match("^S%d+[a-z]$") then
		local num, letter = scene_id:match("^S(%d+)([a-z])$")
		local n = tonumber(num)
		local next_letter = string.char(string.byte(letter) + 1)
		if next_letter > 'z' then
			return "S" .. tostring(n + 1) .. "a"
		end
		return "S" .. tostring(n) .. next_letter
	elseif scene_id:match("^S%d+%.%d+$") then
		local num, sub = scene_id:match("^S(%d+)%.(%d+)$")
		return "S" .. num .. "." .. tostring(tonumber(sub) + 1)
	elseif scene_id:match("^S%d+$") then
		local num = scene_id:match("^S(%d+)$")
		return "S" .. tostring(tonumber(num) + 1)
	end
	return "S1"
end

-- Scan backwards from cursor to find the last scene and generate the next ID
function M.generate_next_scene_id()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i = current_line - 1, 1, -1 do
		local line = lines[i]
		if line then
			local scene_id = extract_scene_id(line)
			if scene_id then
				return M.next_scene_id(scene_id)
			end
		end
	end

	return "S1"
end

-- Build a scene line with optional context
-- context: string or nil. nil = no *...*, empty string = no *...*, non-empty = *context*
function M.build_scene_line(next_id, context)
	if context and context ~= "" then
		return "### " .. next_id .. " *" .. context .. "*"
	end
	return "### " .. next_id
end

-- Show picker for navigating scenes
function M.show_scenes_picker()
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		vim.notify("lonelog: No file name", vim.log.levels.WARN)
		return
	end
	local scenes = M.parse_scenes(bufnr)
	if #scenes == 0 then
		vim.notify("lonelog: No scenes found", vim.log.levels.INFO)
		return
	end
	table.sort(scenes, function(a, b)
		return a.sort_key < b.sort_key
	end)

	if not require("lonelog.config").should_use_telescope() then
		M.show_scenes_browser(scenes)
		return
	end

	-- Build type filter picker
	local summary = M.scenes_summary(scenes)
	local type_items, key_by_label = {}, {}
	table.insert(type_items, "All Scenes (" .. #scenes .. ")")
	key_by_label["All Scenes (" .. #scenes .. ")"] = "all"
	for k, v in pairs(summary) do
		if k ~= "all" then
			local label = v.label .. " (" .. v.count .. ")"
			table.insert(type_items, label)
			key_by_label[label] = k
		end
	end
	local ui_pick = require("lonelog.ui").pick
	ui_pick({
		title = "Filter by Type",
		items = type_items,
		format_item = function(item) return item end,
		on_select = function(choice)
			if not choice then
				return
			end
			local key = key_by_label[choice]
			local filtered = key == "all" and scenes
				or vim.tbl_filter(function(s) return s.type == key end, scenes)
			local items = {}
			for _, s in ipairs(filtered) do
				table.insert(items, { scene = s, display = M.format_scene_display(s) })
			end
			ui_pick({
				title = "Lonelog Scenes",
				items = items,
				format_item = function(item) return item.display end,
				on_select = function(c)
					if c then
						vim.api.nvim_win_set_cursor(0, { c.scene.line, 0 })
					end
				end,
			})
		end,
	})
end

function M.show_scenes_browser(all_scenes)
	local summary = M.scenes_summary(all_scenes)
	local groups = {}
	table.insert(groups, {
		label = "All Scenes (" .. #all_scenes .. ")",
		name = "All Scenes",
		items = all_scenes,
	})
	for k, v in pairs(summary) do
		if k ~= "all" then
			local filtered = vim.tbl_filter(function(s) return s.type == k end, all_scenes)
			table.insert(groups, {
				label = v.label .. " (" .. v.count .. ")",
				name = v.label,
				items = filtered,
			})
		end
	end

	require("lonelog.ui.buffer").open_group_browser({
		title = "Lonelog Scenes",
		groups = groups,
		format_item = M.format_scene_display,
		on_select = function(scene)
			vim.api.nvim_win_set_cursor(0, { scene.line, 0 })
		end,
	})
end

-- Native sidebar picker for scenes
-- Navigate to the previous or next scene
-- direction: -1 for prev, +1 for next
function M.navigate_scene(direction)
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cur_line = cursor[1]

	local scenes = M.parse_scenes(bufnr)
	if #scenes == 0 then
		vim.notify("lonelog: No scenes found", vim.log.levels.INFO)
		return
	end

	M.sort_scenes(scenes)

	local current_idx = 0
	for i, sc in ipairs(scenes) do
		if sc.line <= cur_line then
			current_idx = i
		end
	end

	local target = current_idx + direction
	if current_idx == 0 and direction == -1 then
		vim.notify("lonelog: Cursor is before the first scene", vim.log.levels.INFO)
		return
	elseif target < 1 then
		vim.notify("lonelog: Already at first scene", vim.log.levels.INFO)
		return
	elseif target > #scenes then
		vim.notify("lonelog: Already at last scene", vim.log.levels.INFO)
		return
	end

	vim.api.nvim_win_set_cursor(0, { scenes[target].line, 0 })
	vim.cmd("normal! zz")
end

return M
