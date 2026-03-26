local M = {}
local should_use_telescope = function()
	return require("lonelog.config").should_use_telescope()
end

-- Map scene type keys to labels
local SCENE_TYPES = { main = "Main", flashback = "Flashback", sub = "Sub-scene", thread = "Thread" }
local SCENE_LABELS = { main = "Main Scenes", flashback = "Flashbacks", sub = "Sub-scenes", thread = "Thread Scenes" }

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
			type_label = SCENE_TYPES.thread,
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
			type_label = SCENE_TYPES.flashback,
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
			type_label = SCENE_TYPES.sub,
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
			type_label = SCENE_TYPES.main,
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
		s[sc.type] = s[sc.type] or { label = SCENE_LABELS[sc.type], count = 0 }
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

	if not should_use_telescope() then
		M.show_scenes_picker_native(scenes)
		return
	end

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
	vim.ui.select(type_items, { prompt = "Filter by Type" }, function(choice)
		if not choice then
			return
		end
		local key = key_by_label[choice]
		local filtered = key == "all" and scenes or vim.tbl_filter(function(s)
			return s.type == key
		end, scenes)
		local items = {}
		for _, sc in ipairs(filtered) do
			table.insert(items, M.format_scene_display(sc))
		end
		vim.ui.select(items, { prompt = "Lonelog Scenes" }, function(c)
			if c then
				for i, display in ipairs(items) do
					if display == c then
						vim.api.nvim_win_set_cursor(0, { filtered[i].line, 0 })
						break
					end
				end
			end
		end)
	end)
end

-- Native sidebar picker for scenes
function M.show_scenes_picker_native(all_scenes)
	local summary = M.scenes_summary(all_scenes)
	local type_items, key_by_type = {}, {}
	table.insert(type_items, "All Scenes (" .. #all_scenes .. ")")
	key_by_type[1] = nil
	local idx = 2
	for k, v in pairs(summary) do
		table.insert(type_items, v.label .. " (" .. v.count .. ")")
		key_by_type[idx] = k
		idx = idx + 1
	end

	local sidebar = require("lonelog.ui.sidebar")
	sidebar.open("Scenes", type_items, {
		data = type_items,
		format_item = function(item)
			return item
		end,
		on_select = function(choice)
			local type_idx = 0
			for i, item in ipairs(type_items) do
				if item == choice then
					type_idx = i
					break
				end
			end
			local type_key = key_by_type[type_idx]
			local filtered = type_key and vim.tbl_filter(function(s)
				return s.type == type_key
			end, all_scenes) or all_scenes
			if #filtered == 0 then
				return
			end
			local display_items = {}
			for _, sc in ipairs(filtered) do
				table.insert(display_items, M.format_scene_display(sc))
			end
			sidebar.open("Scenes - " .. choice, display_items, {
				data = filtered,
				on_select = function(scene)
					vim.api.nvim_win_set_cursor(0, { scene.line, 0 })
				end,
			})
		end,
	})
end

return M
